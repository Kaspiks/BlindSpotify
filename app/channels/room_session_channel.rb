# frozen_string_literal: true

# Pattern B: clients subscribe by room code and receive state_json pushes.
# Server is authoritative; clients send actions (e.g. via HTTP), server broadcasts state.
class RoomSessionChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find_by(code: params[:code])
    if @room
      stream_from stream_name
      transmit_state
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def receive(data)
    return unless @room
    action = data["type"].to_s
    payload = data["payload"] || {}
    Rooms::ApplyRoomActionService.call(room: @room, action: action, payload: payload, connection: self)
  end

  private

  def stream_name
    "room_session:#{@room.code}"
  end

  def transmit_state
    transmit({ "state" => @room.state_snapshot })
  end
end
