module RuoteAMQP

  #
  # = AMQP Listeners
  #
  # Used in conjunction with the RuoteAMQP::Participant, the Listener
  # subscribes to a specific direct exchange and monitors for
  # incoming workitems. It expects workitems to arrive serialized as
  # JSON.
  #
  # == Configuration
  #
  # AMQP configuration is handled by directly manipulating the values of
  # the +AMQP.settings+ hash, as provided by the AMQP gem. No
  # defaults are set by the participant. The only +option+ parsed by
  # the initializer of the listener is the +queue+ key (Hash
  # expected). If no +queue+ key is set, the listener will subscribe
  # to the +ruote+ direct exchange for workitems, otherwise it will
  # subscribe to the direct exchange provided.
  #
  # The participant requires version 0.6.1 or later of the amqp gem.
  #
  # == Usage
  #
  # Register the listener with the engine:
  #
  #   engine.register_listener( RuoteAMQP::Listener )
  #
  # The listener leverages the asynchronous nature of the amqp gem,
  # so no timers are setup when initialized.
  #
  # See the RuoteAMQP::Participant docs for information on sending
  # workitems out to remote participants, and have them send replies
  # to the correct direct exchange specified in the workitem
  # attributes.
  #
  class Listener

    include Ruote::EngineContext

    class << self
      attr_accessor :queue
    end

    def initialize( options = {} )
      self.class.queue = options.delete(:queue) || 'ruote'
      RuoteAMQP.with_reactor(:listener) do
        MQ.queue( self.class.queue, :durable => true ).subscribe do |message|
          workitem = decode_workitem( message )
          engine.reply( workitem )
        end
      end
    end

    def stop
      RuoteAMQP.stop(:listener)
    end

    private

    # Complicated guesswork that needs to happen here to detect the format
    def decode_workitem( msg )
      hash = Ruote::Json.decode( msg )
      Ruote::Workitem.from_h( hash )
    end
  end
end
