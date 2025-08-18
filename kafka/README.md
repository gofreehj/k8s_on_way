kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

kubectl -n kafka delete -f 'https://strimzi.io/install/latest?namespace=kafka'

kubectl logs deployment/strimzi-cluster-operator -n kafka -f

kubectl get pods -n kafka


# 构建镜像
docker rmi crpi-umhpg8dvg5qptjum.cn-beijing.personal.cr.aliyuncs.com/prod-scoox/kafka:4.0.0

docker inspect crpi-umhpg8dvg5qptjum.cn-beijing.personal.cr.aliyuncs.com/prod-scoox/kafka:4.0.0 | grep Architecture

docker buildx build --platform linux/amd64 -t crpi-umhpg8dvg5qptjum.cn-beijing.personal.cr.aliyuncs.com/prod-scoox/kafka:4.0.0-2 -f Dockerfile --push .

# 清理集群
kubectl delete kafka kafka-cluster -n kafka --ignore-not-found=true
kubectl delete kafkanodepool controller -n kafka -l app.kubernetes.io/instance=kafka-cluster --ignore-not-found=true
kubectl delete kafkanodepool broker -n kafka -l app.kubernetes.io/instance=kafka-cluster  --ignore-not-found=true
kubectl delete pvc -n kafka -l strimzi.io/cluster=kafka-cluster --ignore-not-found=true
kubectl rollout restart deployment -n kafka

<!-- kubectl delete pods -n kafka -l strimzi.io/cluster=kafka-cluster -->
# 部署集群
kubectl apply -f /Users/amid032185/selfs/codes/ai/kafka/kafka-cluster-s3.yaml -n kafka

# 验证集群
kubectl -n kafka run kafka-producer -ti --image=quay.io/strimzi/kafka:0.47.0-kafka-4.0.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic my-topic


kubectl -n kafka run kafka-consumer -ti --image=quay.io/strimzi/kafka:0.47.0-kafka-4.0.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic my-topic --from-beginning


# 查看 Topic 的配置(wuxiao)
kubectl -n kafka exec -ti kafka-cluster-broker-0 -c kafka -- \
  bin/kafka-configs.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 \
  --entity-type topics --entity-name user-events --describe

# 冷热分离
kubectl exec -n kafka -it kafka-cluster-broker-0 -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic tiered-storage-test \
  --partitions 1 \
  --replication-factor 3 \
  --config remote.storage.enable=true \
  --config local.retention.ms=60000 \
  --config retention.ms=3600000

kubectl exec -n kafka kafka-cluster-dev-broker-0 -- /opt/kafka/bin/kafka-configs.sh \
    --alter --entity-type topics --entity-name tiered-storage-test \
    --add-config local.retention.ms=60000 \
    --bootstrap-server localhost:9092

kubectl exec -n kafka kafka-cluster-dev-broker-0 -- /opt/kafka/bin/kafka-topics.sh --describe --topic tiered-storage-test --bootstrap-server localhost:9092

# producer
kubectl exec -n kafka -it kafka-cluster-broker-0 -- /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic tiered-storage-test

# consumer
kubectl exec -n kafka -it kafka-cluster-broker-1 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic tiered-storage-test \
  --from-beginning


# Fill Test Data
kubectl exec -n kafka -it kafka-cluster-broker-0 -- /opt/kafka/bin/kafka-producer-perf-test.sh \
    --topic tiered-storage-test --num-records=10000 --throughput -1 --record-size 1000 \
    --producer-props acks=1 batch.size=16384 bootstrap.servers=localhost:9092

 kubectl logs -n kafka kafka-cluster-broker-0 | grep -i -E "s3|error|failed|exception" 


 # 查看 broker-0 的日志，搜索与 tiered storage 相关的关键词
kubectl logs -n kafka kafka-cluster-broker-0 -c kafka | grep -i "tiered\|remote\|offload\|s3\|storage"


查看Kafka broker节点的ESSD存储挂载情况
kubectl exec -n kafka kafka-cluster-broker-0 -- df -h | grep -v tiered

kubectl logs -n kafka kafka-cluster-dev-broker-0 -c kafka | grep -i "RemoteLogManager" -C 100

kubectl exec -n kafka kafka-cluster-dev-broker-0 -- ls -la /var/lib/kafka/data-0/kafka-log0

kubectl exec -n kafka kafka-cluster-dev-broker-0 -- ls -lh /var/lib/kafka/data-0/kafka-log0/tiered-storage-test-0