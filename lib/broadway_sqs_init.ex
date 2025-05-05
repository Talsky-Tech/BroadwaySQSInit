defmodule BroadwaySQSInit do
  @moduledoc """
  A utility module to ensure an SQS queue exists before starting a Broadway pipeline.
  It checks if the queue exists using `ExAws.SQS.get_queue_url/1` and creates it with
  `ExAws.SQS.create_queue/2` if it doesn't. Returns the queue URL for use in Broadway configuration.
  """

  @doc """
  Ensures the specified SQS queue exists, creating it if necessary.

  ## Parameters
    - opts: A map containing:
      - `:queue_name` (required): The name of the SQS queue.
      - `:aws_config` (required): A map with AWS credentials (`access_key_id`, `secret_access_key`, `region`).
      - `:queue_attributes` (optional): A map of queue attributes (e.g., `fifo_queue: true`).

  ## Returns
    - The queue URL as a string.

  ## Raises
    - If the queue cannot be accessed or created, an exception is thrown with the error details.

  ## Example
      queue_url = BroadwaySQSInit.ensure_queue_exists(
        "my_queue.fifo",
        %{fifo_queue: true, content_based_deduplication: true},
        %{
          access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
          secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
          region: "us-east-1"
        }
      })

      Broadway.start_link(MyBroadway,
        name: MyBroadway,
        producer: [
          module: {BroadwaySQS.Producer,
            queue_url: queue_url,
            config: [
              access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
              secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
              region: "us-east-1"
            ]
          }
        ]
      )
  """
  @spec ensure_queue_exists(queue_name :: String.t(), queue_attributes :: map(), config_overrides :: keyword()) :: String.t()
  def ensure_queue_exists(queue_name, queue_attributes, config_overrides \\ []) do
    queue_name
    |> ExAws.SQS.get_queue_url()
    |> ExAws.request(config_overrides)
    |> maybe_create_queue(queue_name, queue_attributes, config_overrides)
  end


  @spec maybe_create_queue({:ok, term()} | {:error, term()}, String.t(), map(), keyword()) :: String.t()
  defp maybe_create_queue({:ok, %{body: %{queue_url: queue_url}, status_code: 200}}, _, _, _), do: queue_url

  defp maybe_create_queue({:error, {:http_error, 400, %{code: "AWS.SimpleQueueService.NonExistentQueue"}}}, queue_name, queue_attributes, config_overrides) do
    queue_name
    |> ExAws.SQS.create_queue(queue_attributes)
    |> ExAws.request(config_overrides)
    |> case do
        {:ok, %{body: %{queue_url: created_queue_url}}} -> created_queue_url
        {:error, error} -> raise "Failed to create queue: #{inspect(error)}"
      end
  end

  defp maybe_create_queue({:error, error}, _, _, _), do: raise "Failed to get queue URL: #{inspect(error)}"
end
