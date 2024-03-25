defmodule ProcessRing do
  def main() do
    process_list = ProcessRing.create_processes(5)
    ring = ProcessRing.create_ring(process_list)
    ProcessRing.start_ring(ring)
    :timer.sleep(60000) # 1 minute delay between messages
  end    

  def create_processes(size) do
    1..size |> Enum.map(fn _ -> spawn(fn -> process_listener() end) end)
  end

  def create_ring(processes_list) do
    Enum.with_index(processes_list)
    |> Enum.map(fn {process, position} ->
      next_process_pid = Enum.at(processes_list, position + 1)
      first_ring_process = Enum.at(processes_list, 0)
      if next_process_pid do
        %{pid: process, position: position, next_process: next_process_pid}
      else
        %{pid: process, position: position, next_process: first_ring_process}
      end
    end)
  end

  def start_ring(ring) do
    first_ring_process = Enum.at(ring, 0).pid
    ring_size = Enum.count(ring)
    send_message(first_ring_process, ring, (ring_size - 1))
  end

  def process_listener() do
    receive do
      {:message, ring, sender_position} ->
        actual_process_position = rem(sender_position + 1, Enum.count(ring))
        next_process_pid = Enum.at(ring, actual_process_position).next_process

        :timer.sleep(1000) # 1 second delay between messages

        send_message(next_process_pid, ring, actual_process_position)
        process_listener()
      end
  end

  def send_message(process_pid, ring, position) do
    send(process_pid, {:message, ring, position})

    if position == 0 do
      IO.puts("\n[+] New Cycle Started.")
    end

    IO.puts("[.] #{inspect(self())} SENT A MESSAGE TO #{inspect(process_pid)}")
  end
end

ProcessRing.main()
