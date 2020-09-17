import pika
import ssl

username = 'admin'
password = 'rabbit'

host='mq01.rabbit.ops'
port=5671

ca_cert = '/home/chaminda/github/rabbitmq-cluster/config/tls/ca.bundle.pem'
client_cert = '/home/chaminda/github/rabbitmq-cluster/config/tls/client.rabbit.ops.crt.pem'
client_key = '/home/chaminda/github/rabbitmq-cluster/config/tls/client.rabbit.ops.key.pem'


credentials = pika.PlainCredentials(username, password)
context = ssl.create_default_context(cafile=ca_cert)
context.load_cert_chain(client_cert, client_key)
ssl_options = pika.SSLOptions(context, host)
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host,
        credentials=credentials,
        ssl_options=ssl_options,
        virtual_host='/',
        port=port
    )
)

