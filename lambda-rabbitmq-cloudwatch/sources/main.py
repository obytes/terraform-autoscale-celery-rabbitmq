#!/usr/bin/env python3
from __future__ import with_statement, print_function
from base64 import b64decode
import os
import time
import urllib


import boto3
from botocore.vendored import requests


def get_queue_depths_and_publish_to_cloudwatch(host,
                                               port,
                                               username,
                                               password,
                                               vhost,
                                               namespace):
    """
    Calls the RabbitMQ API to get a list of queues and populate cloudwatch

    :param host:
    :param port:
    :param username:
    :param password:
    :param vhost:
    :param namespace:
    :return:
    """
    depths = get_queue_depths(host, port, username, password, vhost)
    publish_depths_to_cloudwatch(depths, namespace)


def get_queue_depths(host, port, username, password, vhost):
    """
    Get a list of queues and their message counts

    :param host:
    :param port:
    :param username:
    :param password:
    :param vhost:
    :return:
    """
    # Get list of queues
    try:
        r = requests.get('https://{}:{}/api/queues'.format(host, port),
                         auth=requests.auth.HTTPBasicAuth(username, password))
    except requests.exceptions.RequestException as e:
        log('rabbitmq_connection_failures')
        print("ERROR: Could not connect to {}:{} with user {}".format(
            host, port, username))
        return []

    queues = r.json()
    total = 0
    depths = {}
    for q in queues:

        # Ignore celery and pyrabbit queues
        if q['name'] == "aliveness-test":
            continue
        elif q['name'].endswith('.pidbox') or q['name'].startswith('celeryev.'):
            continue

        # Get individual queue counts
        try:
            r = requests.get('https://{}:{}/api/queues/{}/{}'.format(
                host,
                port,
                urllib.parse.quote_plus(vhost),
                urllib.parse.quote_plus(q['name'])),
                auth=requests.auth.HTTPBasicAuth(username, password))
        except requests.exceptions.RequestException as e:
            log('queue_depth_failure', tags=['queue:{}'.format(q['name'])])
            break

        qr = r.json()
        if r.status_code == 200 and 'messages' in qr:
            queue_depth = qr['messages']
            depths[q['name']] = queue_depth
            total = total + int(queue_depth)
        else:
            log('queue_depth_failure', tags=['queue:{}'.format(q['name'])])

    depths['total'] = str(total)
    return depths


def publish_depths_to_cloudwatch(depths, namespace):
    """

    :param depths:
    :param namespace:
    :return:
    """
    cloudwatch = boto3.client(
        'cloudwatch', region_name=os.environ.get("AWS_REGION"))
    for q in depths:
        try:
            cloudwatch.put_metric_data(
                Namespace=namespace,
                MetricData=[{
                    'MetricName': q,
                    'Timestamp': time.time(),
                    'Value': int(depths[q]),
                    'Unit': 'Count',
                }])
            log(namespace, 'gauge', depths[q], [
                'queue:' + q
            ])
        except Exception as e:
            print(str(e))
            log('cloudwatch_put_metric_error')


def lambda_handler(event, context):

    queue_group = context.function_name.split('-', 1)[0]

    host = os.environ.get("RABBITMQ_HOST")
    port = os.environ.get("RABBITMQ_PORT")
    user = os.environ.get("RABBITMQ_USER")
    pw = os.environ.get("RABBITMQ_PASS")
    get_queue_depths_and_publish_to_cloudwatch(
        host=host,
        port=port,
        username=user,
        password=boto3.client('kms').decrypt(CiphertextBlob=b64decode(pw))[
            'Plaintext'].decode('utf8').replace('\n', ''),
        vhost="/",
        namespace=queue_group + ".rabbitmq.depth")


def log(metric_name, metric_type='count', metric_value=1, tags=[]):
    """
    :param metric_name:
    :param metric_type:
    :param metric_value:
    :param tags:
    :return:
    """
    # MONITORING|unix_epoch_timestamp|metric_value|metric_type|my.metric.name|#tag1:value,tag2
    print("MONITORING|{}|{}|{}|{}|#{}".format(
        int(time.time()),
        metric_value,
        metric_type,
        'rabbitmq_cloudwatch.' + metric_name, ','.join(tags)))


if __name__ == "__main__":
    lambda_handler(event=None, context=None)
