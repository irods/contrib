#!/usr/bin/python3

import argparse
import time
import json
import sys
import logging
from enum import Flag, auto
from threading import Lock
from pprint import pformat

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

def get_argparser():
	default_mut = Workarounds.TYPING
	parser = argparse.ArgumentParser(
		description='AMQP 1.0 fluent Logstash stand-in daemon',
		allow_abbrev=False
	)
	parser.add_argument(
		'--workarounds', metavar='MUTATOR',
		type=Workarounds,
		action=FlagAction, dest='workarounds', nargs='+',
		default=default_mut,
		help=f'Specify which workarounds to enable (available: {~Workarounds.NONE}; default: {default_mut})'
	)
	return parser

class FlagArg(Flag):
	@classmethod
	def _from_arg_str(cls, s: str) -> Flag:
		name_map = {str(f): f for f in cls}
		zero = cls(0)
		if zero.name is not None:
			name_map[str(zero)] = zero
		names = [n for n in s.split(',') if n]
		value = cls(0)
		for name in names:
			try:
				value = value | name_map[name]
			except KeyError:
				raise argparse.ArgumentTypeError(
					f"{name!r} is not a valid {cls.__name__}")
		return value

	def __str__(self):
		if len(self) == 0:
			return str(self.name or self.value).lower()
		return ','.join([str(m.name or m.value).lower() for m in self])

class FlagAction(argparse._StoreAction):
	def __init__(self, *args, type=None, **kwargs):
		super(FlagAction, self).__init__(*args, type=type._from_arg_str, **kwargs)
		self.flag_type = type

	def __call__(self, parser, namespace, values, *args, **kwargs):
		value = self.flag_type(0)
		for v in values:
			value = value | v
		super(FlagAction, self).__call__(parser, namespace, value, *args, **kwargs)

class Workarounds(FlagArg, Flag):
	NONE = 0
	TOKENS = auto()
	TYPING = auto()
	TIMESTAMP = auto()

class ELKReader(MessagingHandler):
	def __init__(self, server, address, workarounds=Workarounds.NONE):
		self.logger = logging.getLogger('ELKReader')
		super(ELKReader, self).__init__()
		self.workaround_tokens = self._w_tokens if Workarounds.TOKENS in workarounds else self._w_noop
		self.workaround_typing = self._w_typing if Workarounds.TYPING in workarounds else self._w_noop
		self.workaround_ts = self._w_ts if Workarounds.TIMESTAMP in workarounds else self._w_noop
		self.server = server
		self.address = address
		self.id_ctr = 0
		self.id_ctr_lock = Lock()
		self.es = Elasticsearch(hosts=[{'host':'localhost', 'port':9200}])

	def on_start(self, event):
		conn = event.container.connect(self.server)
		event.container.create_receiver(conn, self.address)

	def _w_noop(self, *args, **kwargs):
		pass

	def _w_tokens(self, message):
		message.body = message.body.replace("__BEGIN_JSON__","").replace("__END_JSON__", "")

	def _w_typing(self, body_obj):
		#msg.pop('const_char_ptr__3', None)
		for convert_int_key in convert_int:
			if convert_int_key in body_obj:
				body_obj[convert_int_key] = int(body_obj[convert_int_key])

	def _w_ts(self, body_obj):
		timestamp = body_obj.pop('time_stamp')
		timestamp = int(timestamp)
		body_obj['@timestamp'] = timestamp

	def on_message(self, event):
		with self.id_ctr_lock:
			msg_id = self.id_ctr
			self.id_ctr += 1

		msg = event.message

		self.workaround_tokens(msg)

		try:
			body_obj = json.loads(msg.body)
		except json.JSONDecodeError:
			self.logger.exception('Failed to decode JSON from AMQP message. body(raw):\n%s', pformat(msg.body))
			return

		self.workaround_ts(body_obj)
		self.workaround_typing(body_obj)

		try:
			self.es.index(
				index = "irods_audit",
				id = msg_id,
				body = body_obj
			)
		except Exception:
			self.logger.exception('ES exception. body:\n%s', pformat(body_obj))

def _main():
	args = get_argparser().parse_args()

	while True:
		time.sleep(1)
		Container(ELKReader("localhost:5672", "audit_messages", args.workarounds)).run()
	return 0

if __name__ == '__main__':
	sys.exit(_main())
