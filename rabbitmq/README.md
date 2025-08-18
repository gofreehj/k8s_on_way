kubectl rabbitmq -n rabbitmq-system delete rabbitmq-cluster


kubectl apply -f /Users/amid032185/selfs/codes/ai/rabbitmq/rabbitmq-cluster.yaml -n rabbitmq-system

instance=INSTANCE-NAME
username=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.username}" | base64 --decode)
password=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.password}" | base64 --decode)
service=${instance}
kubectl run perf-test --image=pivotalrabbitmq/perf-test -- --uri "amqp://${username}:${password}@${service}"



kubectl get secret -n rabbitmq-system rabbitmq-cluster-default-user -o jsonpath="{.data.username}" | base64 --decode
kubectl get secret -n rabbitmq-system rabbitmq-cluster-default-user -o jsonpath="{.data.password}" | base64 --decode


default_user_Pi7Ayjj7U9thng5Uz6j
uvyWhnVO_DDh3SgcHPmiJKZ1FEWsWTRZ