问题记录
# 使用filesystem（oss)
1. must be a writable directory


2025-08-05 00:53:24 ERROR [main] Kafka$:28 - Exiting Kafka due to fatal exception during startup.
java.lang.IllegalArgumentException: /mnt/tiered-storage must be a writable directory
	at io.aiven.kafka.tieredstorage.storage.filesystem.FileSystemStorage.configure(FileSystemStorage.java:46) ~[?:?]
	at io.aiven.kafka.tieredstorage.config.RemoteStorageManagerConfig.storage(RemoteStorageManagerConfig.java:318) ~[?:?]
	at io.aiven.kafka.tieredstorage.RemoteStorageManager.configure(RemoteStorageManager.java:151) ~[?:?]
	at org.apache.kafka.server.log.remote.storage.ClassLoaderAwareRemoteStorageManager.lambda$configure$0(ClassLoaderAwareRemoteStorageManager.java:48) ~[kafka-storage-4.0.0.jar:?]
	at org.apache.kafka.server.log.remote.storage.ClassLoaderAwareRemoteStorageManager.withClassLoader(ClassLoaderAwareRemoteStorageManager.java:65) ~[kafka-storage-4.0.0.jar:?]
	at org.apache.kafka.server.log.remote.storage.ClassLoaderAwareRemoteStorageManager.configure(ClassLoaderAwareRemoteStorageManager.java:47) ~[kafka-storage-4.0.0.jar:?]
	at kafka.log.remote.RemoteLogManager.configureRSM(RemoteLogManager.java:380) ~[kafka_2.13-4.0.0.jar:?]
	at kafka.log.remote.RemoteLogManager.startup(RemoteLogManager.java:419) ~[kafka_2.13-4.0.0.jar:?]

# 使用s3 
问题记录
1. Missing Some Required Arguments
   
kubectl logs -n kafka kafka-cluster-broker-0 -c kafka | grep -i "offload\|s3\|oss"
2025-08-04 11:40:40 INFO  [main] AbstractConfig:371 - S3StorageConfig values: 
	s3.api.call.attempt.timeout = null
	s3.api.call.timeout = null
	s3.bucket.name = pv-kafka-dev
	s3.endpoint.url = https://oss-cn-hangzhou.aliyuncs.com  
	s3.multipart.upload.part.size = 26214400
	s3.path.style.access.enabled = false
	s3.region = cn-hangzhou
	s3.storage.class = STANDARD
org.apache.kafka.server.log.remote.storage.RemoteStorageException: software.amazon.awssdk.services.s3.model.S3Exception: Missing Some Required Arguments. (Service: S3, Status Code: 400, Request ID: 68909C3F6FB42B30365D59FB) (SDK Attempt Count: 1)
Caused by: software.amazon.awssdk.services.s3.model.S3Exception: Missing Some Required Arguments. (Service: S3, Status Code: 400, Request ID: 68909C3F6FB42B30365D59FB) (SDK Attempt Count: 1)
	at software.amazon.awssdk.services.s3.model.S3Exception$BuilderImpl.build(S3Exception.java:113) ~[?:?]
	at software.amazon.awssdk.services.s3.model.S3Exception$BuilderImpl.build(S3Exception.java:61) ~[?:?]
	at software.amazon.awssdk.services.s3.DefaultS3Client.deleteObjects(DefaultS3Client.java:3640) ~[?:?]
	at io.aiven.kafka.tieredstorage.storage.s3.S3Storage.delete(S3Storage.java:109) ~[?:?]
org.apache.kafka.server.log.remote.storage.RemoteStorageException: software.amazon.awssdk.services.s3.model.S3Exception: Missing Some Required Arguments. (Service: S3, Status Code: 400, Request ID: 68909C5D6FB42B3036230FFC) (SDK Attempt Count: 1)