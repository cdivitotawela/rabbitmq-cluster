import pika
import unittest
from os import path
from os import environ
import ssl
import time

class RabbitMQTests(unittest.TestCase):

    connection = None
    channel = None

    def setUp(self):
        # If TLS enabled CA certificate file should be provided
        if ENV_PARAMETERS['AMQP_TLS_ENABLED']['value']:
            if not path.exists(ENV_PARAMETERS['AMQP_CA_CERT_FILE']['value']):
                raise FileExistsError("CA certificate file {} not exist".format(environ['AMQP_CA_CERT_FILE']['value']))
            context = ssl.create_default_context(cafile=ENV_PARAMETERS['AMQP_CA_CERT_FILE']['value'])

            # If client auth enabled then client certificate and key must be provided
            if ENV_PARAMETERS['AMQP_CLIENT_AUTH_ENABLED']['value']:
                if not path.exists(ENV_PARAMETERS['AMQP_CERT_FILE']['value']):
                    raise FileExistsError(
                        "Client certificate file {} not exist".format(ENV_PARAMETERS['AMQP_CERT_FILE']['value']))

                if not path.exists(ENV_PARAMETERS['AMQP_KEY_FILE']['value']):
                    raise FileExistsError(
                        "Client certificate key file {} not exist".format(ENV_PARAMETERS['AMQP_KEY_FILE']['value']))
                context.load_cert_chain(
                    ENV_PARAMETERS['AMQP_CERT_FILE']['value'],
                    ENV_PARAMETERS['AMQP_KEY_FILE']['value']
                )

            ssl_options = pika.SSLOptions(
                context,
                ENV_PARAMETERS['HOST']['value']
            )

            if ENV_PARAMETERS['USERNAME']['value'] is not None and ENV_PARAMETERS['PASSWORD']['value'] is not None:
                credentials = pika.PlainCredentials(ENV_PARAMETERS['USERNAME']['value'],
                                                    ENV_PARAMETERS['PASSWORD']['value'])
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=ENV_PARAMETERS['HOST']['value'],
                        credentials=credentials,
                        virtual_host=ENV_PARAMETERS['VHOST']['value'],
                        ssl_options=ssl_options
                    )
                )
            else:
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=ENV_PARAMETERS['HOST']['value'],
                        virtual_host=ENV_PARAMETERS['VHOST']['value'],
                        ssl_options=ssl_options
                    )
                )


        else:
            if ENV_PARAMETERS['USERNAME']['value'] is not None and ENV_PARAMETERS['PASSWORD']['value'] is not None:
                credentials = pika.PlainCredentials(ENV_PARAMETERS['USERNAME']['value'],
                                                    ENV_PARAMETERS['PASSWORD']['value'])
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=ENV_PARAMETERS['HOST']['value'],
                        credentials=credentials,
                        virtual_host=ENV_PARAMETERS['VHOST']['value']
                    )
                )
            else:
                self.connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=ENV_PARAMETERS['HOST']['value'],
                        virtual_host=ENV_PARAMETERS['VHOST']['value']
                    )
                )
        self.channel = self.connection.channel()

    def test_send_message(self):

        q_name = 'unit-test'
        ts = int(time.time())
        message = 'msg-{}'.format(ts)

        # Create queue
        self.channel.queue_declare(queue=q_name)

        # Publish message to queue
        self.channel.basic_publish(
            exchange='',
            routing_key=q_name,
            body=message
        )

        # Retrieve message from the queue
        method_frame, header_frame, body = self.channel.basic_get(queue=q_name)
        self.channel.basic_ack(method_frame.delivery_tag)

        # Close connection before asserting
        self.connection.close()

        # Assert published message and retrieved message
        self.assertEqual(body.decode(), message)


if __name__ == '__main__':

    # Default values for environment variables.
    ENV_PARAMETERS = {
        'HOST': {
            'value': 'localhost',
            'type': 'str'
        },
        'PORT': {
            'value': 5671,
            'type': 'int'
        },
        'USERNAME': {
            'value': None,
            'type': 'str'
        },
        'PASSWORD': {
            'value': None,
            'type': 'str'
        },
        'VHOST': {
            'value': '/',
            'type': 'str'
        },
        'QNAME': {
            'value': None,
            'type': 'str'
        },
        'AMQP_TLS_ENABLED': {
            'value': False,
            'type': 'bool'
        },
        'AMQP_CA_CERT_FILE': {
            'value': None,
            'type': 'str'
        },
        'AMQP_CLIENT_AUTH_ENABLED': {
            'value': False,
            'type': 'bool'
        },
        'AMQP_CERT_FILE': {
            'value': None,
            'type': 'str'
        },
        'AMQP_KEY_FILE': {
            'value': None,
            'type': 'str'
        }
    }

    ##########################
    # Update default parameters with configured environment parameters
    ##########################
    for key in ENV_PARAMETERS:
        if key in environ:
            if ENV_PARAMETERS[key]['type'] == 'str':
                ENV_PARAMETERS[key]['value'] = environ[key]
            elif ENV_PARAMETERS[key]['type'] == 'bool':
                ENV_PARAMETERS[key]['value'] = bool(environ[key])
            elif ENV_PARAMETERS[key]['type'] == 'int':
                ENV_PARAMETERS[key]['value'] = int(environ[key])

    ##########################
    # Validations
    ##########################
    if ENV_PARAMETERS['QNAME']['value'] is None:
        raise ValueError('Environment varaible QNAME must be set')

    unittest.main()
