defmodule BroadwaySQSInitTest do
  use ExUnit.Case

  defmodule FakeSQSClient do
    @behaviour ExAws.Request.HttpClient

    @get_queue_url_error_body """
    <ErrorResponse>
      <Error>
        <Type>Sender</Type>
        <Code>AWS.SimpleQueueService.NonExistentQueue</Code>
        <Message>The specified queue does not exist.</Message>
      </Error>
      <RequestId>some-request-id</RequestId>
    </ErrorResponse>
    """

    def request(:post, _url, body, _headers, _opts) do
      query = parse_query(body)
      action = query["Action"]
      queue_name = query["QueueName"]
      state = Process.get(:fake_sqs_state, %{})
      requests = Keyword.get(state, :requests, []) ++ [body]
      Process.put(:fake_sqs_state, Keyword.put(state, :requests, requests))

      case action do
        "GetQueueUrl" ->
          if Keyword.get(state, :queue_exists, false) do
            queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/#{queue_name}"
            body = """
            <GetQueueUrlResponse>
              <GetQueueUrlResult>
                <QueueUrl>#{queue_url}</QueueUrl>
              </GetQueueUrlResult>
              <ResponseMetadata>
                <RequestId>some-request-id</RequestId>
              </ResponseMetadata>
            </GetQueueUrlResponse>
            """
            {:ok, %Req.Response{status: 200, body: body}}
          else
            {:ok, %Req.Response{status: 400, body: @get_queue_url_error_body}}
          end
        "CreateQueue" ->
          queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/#{queue_name}"
          body = """
          <CreateQueueResponse>
            <CreateQueueResult>
              <QueueUrl>#{queue_url}</QueueUrl>
            </CreateQueueResult>
            <ResponseMetadata>
              <RequestId>some-request-id</RequestId>
            </ResponseMetadata>
          </CreateQueueResponse>
          """
          {:ok, %Req.Response{status: 200, body: body}}
        _ ->
          {:error, :unknown_action}
      end
    end


    defp parse_query(body) do
      body
      |> String.split("&")
      |> Enum.map(fn part -> String.split(part, "=", parts: 2) end)
      |> Enum.into(%{}, fn [k, v] -> {k, v} end)
    end

    def get_requests do
      Process.get(:fake_sqs_state, %{})[:requests] || []
    end
  end

  describe "ensure_queue_exists/1" do
    test "when queue exists, returns queue URL without creating" do
      Process.put(:fake_sqs_state, queue_exists: true, requests: [])

      aws_config =  %{
        http_client: FakeSQSClient,
        access_key_id: "some_key",
        secret_access_key: "some_secret",
        region: "us-east-1"
      }

      queue_url = BroadwaySQSInit.ensure_queue_exists("my_queue", %{}, aws_config)
      assert queue_url == "https://sqs.us-east-1.amazonaws.com/123456789012/my_queue"
      requests = FakeSQSClient.get_requests()
      assert length(requests) == 1
      assert hd(requests) =~ "Action=GetQueueUrl&QueueName=my_queue"
    end

    test "when queue does not exist, creates queue and returns queue URL" do
      Process.put(:fake_sqs_state, queue_exists: false, requests: [])

      aws_config =  %{
        http_client: FakeSQSClient,
        access_key_id: "some_key",
        secret_access_key: "some_secret",
        region: "us-east-1"
      }

      queue_url = BroadwaySQSInit.ensure_queue_exists("my_queue", %{}, aws_config)

      assert queue_url == "https://sqs.us-east-1.amazonaws.com/123456789012/my_queue"
      requests = FakeSQSClient.get_requests()
      assert length(requests) == 2
      assert Enum.at(requests, 0) =~ "Action=GetQueueUrl&QueueName=my_queue"
      assert Enum.at(requests, 1) =~ "Action=CreateQueue&QueueName=my_queue"
    end
  end
end
