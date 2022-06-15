#!/usr/bin/python3

import time
import json
from datetime import datetime
from threading import Lock

from proton import Message
from proton.handlers import MessagingHandler
from proton.reactor import Container
from elasticsearch import Elasticsearch

# There's way more than this that needs conversion.
# I think that we have to do this at all means we're constructing our json improperly.
# Ugh.
convert_int = [
  'int',
  'int__2',
  'int__3',
  'file_size'
]

class ELKReader(MessagingHandler):
  def __init__(self, server, address):
    super(ELKReader, self).__init__()
    self.server = server
    self.address = address
    self.id_ctr = 0
    self.id_ctr_lock = Lock()
    self.es = Elasticsearch(hosts=[{'host':'localhost', 'port':9200}])

  def on_start(self, event):
    conn = event.container.connect(self.server)
    event.container.create_receiver(conn, self.address)

  def on_message(self, event):
    with self.id_ctr_lock:
      msg_id = self.id_ctr
      self.id_ctr += 1

    msg = event.message.body

    # remove bad workaround tokens
    msg = msg.replace("__BEGIN_JSON__","").replace("__END_JSON__", "")

    msg = json.loads(msg)

    timestamp = datetime.fromtimestamp(int(msg.pop('time_stamp')) / 1000.0)
    msg['@timestamp'] = timestamp.isoformat()

    #msg.pop('const_char_ptr__3', None)

    for convert_int_key in convert_int:
      if convert_int_key in msg:
        msg[convert_int_key] = int(msg[convert_int_key])

    self.es.index(
      index = "irods_audit",
      id = msg_id,
      body = msg
    )

while True:
  time.sleep(1)
  Container(ELKReader("localhost:5672", "audit_messages")).run()
