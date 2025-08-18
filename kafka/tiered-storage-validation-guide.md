# Kafka 分层存储完整性验证手册

本文档提供了验证 Strimzi Kafka 集群中分层存储（热数据使用 ESSD，冷数据使用 OSS）配置完整性的详细步骤。

## 1. 验证前提条件

在进行验证之前，请确保：

1. Kafka 集群已成功部署并运行
2. 分层存储配置已应用
3. 已创建测试用的 Topic

## 2. 验证步骤

### 2.1 检查 Kafka 集群状态

首先，确认 Kafka 集群的 Pod 正常运行：

```bash
kubectl get pods -n kafka
```

预期输出应显示 controller 和 broker 的 Pod 都处于 `Running` 状态。

### 2.2 检查分层存储配置

检查 Kafka 集群配置中是否启用了分层存储：

```bash
kubectl get kafka kafka-cluster -n kafka -o yaml | grep -A 10 tieredStorage
```

确认配置中包含正确的 RemoteStorageManager 类和配置参数。

### 2.3 检查存储卷挂载

验证 broker Pod 是否正确挂载了 ESSD 和 OSS 存储卷：

```bash
kubectl exec -n kafka kafka-cluster-broker-0 -- df -h | grep tiered
```

应该能看到 OSS 存储卷已挂载到 [/mnt/tiered-storage](file:///Users/amid032185/selfs/codes/ai/kafka/kafka-oss-storageclass.yaml#L16-L16) 目录。

### 2.4 检查权限设置

验证 initContainer 是否正确设置了 OSS 存储目录的权限：

```bash
kubectl exec -n kafka kafka-cluster-broker-0 -- ls -ld /mnt/tiered-storage
```

目录应该由用户 ID 1001 拥有，并且具有写权限。

### 2.5 创建测试 Topic

创建一个用于测试分层存储的 Topic：

```bash
kubectl exec -n kafka -it kafka-cluster-controller-0 -- /opt/kafka/bin/kafka-topics.sh \
    --create --topic tiered-storage-test \
    --partitions 3 --replication-factor 3 \
    --config remote.storage.enable=true \
    --config local.retention.ms=1000 \
    --bootstrap-server localhost:9092
```

这里设置了 `remote.storage.enable=true` 启用远程存储，并且设置 `local.retention.ms=1000` 使数据快速转移到远程存储。

### 2.6 生成测试数据

使用 Kafka 自带的性能测试工具生成测试数据：

```bash
kubectl exec -n kafka -it kafka-cluster-broker-0 -- /opt/kafka/bin/kafka-producer-perf-test.sh \
    --topic tiered-storage-test --num-records=10000 --throughput -1 --record-size 1000 \
    --producer-props acks=1 batch.size=16384 bootstrap.servers=localhost:9092
```

### 2.7 验证数据分层

等待一段时间（超过 `local.retention.ms` 设置的时间）后，检查本地和远程存储的数据分布：

```bash
# 检查本地存储使用情况
kubectl exec -n kafka kafka-cluster-broker-0 -- du -sh /var/lib/kafka

# 如果配置了日志记录，可以查看分层存储相关的日志
kubectl logs -n kafka kafka-cluster-broker-0 | grep -i tiered
```

### 2.8 验证数据可读性

使用消费者验证数据是否可读：

```bash
# 创建消费者并从头开始消费
kubectl exec -n kafka -it kafka-cluster-controller-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
    --topic tiered-storage-test \
    --from-beginning \
    --bootstrap-server localhost:9092 \
    --max-messages 100
```

如果能正常消费到之前生产的数据，说明分层存储配置成功。

### 2.9 检查 OSS 中的数据

登录阿里云控制台，检查指定的 OSS bucket 中是否已存储来自 Kafka 的数据。

## 3. 故障排除

如果验证过程中遇到问题，请按以下步骤进行排查：

### 3.1 权限问题

如果遇到 "/mnt/tiered-storage must be a writable directory" 错误：

1. 检查 initContainer 是否正确配置并运行
2. 验证 OSS 存储卷是否正确挂载
3. 确认 StorageClass 和 PVC 中是否添加了 `-o mp_umask=022` 参数

### 3.2 配置问题

如果分层存储未按预期工作：

1. 检查 Kafka 配置中 `remote.storage.enable` 是否设置为 true
2. 确认 `local.retention.ms` 设置合理
3. 验证 RemoteStorageManager 配置是否正确

### 3.3 网络连接问题

如果 Kafka 无法连接到 OSS：

1. 检查 RRSA 配置是否正确
2. 确认 RAM 角色权限是否正确设置
3. 验证网络策略是否允许访问 OSS

## 4. 性能调优建议

1. 根据实际负载调整 `local.retention.ms` 和 `retention.ms` 参数
2. 适当设置 `remote.log.segment.size.bytes` 以平衡存储效率和检索性能
3. 监控 OSS 的访问延迟和成本