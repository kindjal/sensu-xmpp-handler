#!/usr/bin/env ruby
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'xmpp4r/client'
require 'xmpp4r/muc'
include Jabber

class XmppHandler < Sensu::Handler

  def config
    xmpp_jid = settings['xmpp']['jid']
    xmpp_password = settings['xmpp']['password']
    xmpp_target = settings['xmpp']['target']
    xmpp_target_type = settings['xmpp']['target_type']
    xmpp_server = settings['xmpp']['server']
  end

  def event_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def message
    if @event['action'].eql?("resolve")
      body = "Sensu RESOLVED - [#{event_name}] - #{@event['check']['notification']}"
    else
      body = "Sensu ALERT - [#{event_name}] - #{@event['check']['notification']}"
    end
  end

  def handle
    jid = JID::new(config.xmpp_jid)
    cl = Client::new(jid)
    cl.connect(config.xmpp_server)
    cl.auth(config.xmpp_password)
    if xmpp_target_type == 'conference'
      m = Message::new(config.xmpp_target, message.body)
      room = MUC::MUCClient.new(cl)
      room.join(Jabber::JID.new(config.xmpp_target+'/'+cl.jid.node))
      room.send m
    else
      m = Message::new(config.xmpp_target, message.body).set_type(:normal).set_id('1').set_subject("SENSU ALERT!")
      cl.send m
    end
  end

end
