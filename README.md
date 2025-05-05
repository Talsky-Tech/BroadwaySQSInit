# BroadwaySQSInit
A utility to ensure an SQS queue exists before starting a Broadway pipeline.

## Background and Motivation

Broadway is a powerful Elixir library for building concurrent, multi-stage data ingestion and processing pipelines, leveraging the Erlang VM’s actor model for scalability and fault tolerance. It supports various message brokers, including Amazon Simple Queue Service (SQS), through the broadway_sqs library, which provides the BroadwaySQS.Producer module. This producer requires a valid SQS queue URL to operate, assuming the queue already exists. However, in many applications, ensuring the queue’s existence programmatically at startup is desirable to avoid manual setup and enhance automation, especially across multiple projects.

The goal is to create an open-source Elixir library, "Broadway SQS Init" that standardizes the startup procedure for Broadway pipelines using SQS. The library should check if the specified SQS queue exists, create it if it doesn’t, and then start the Broadway pipeline with the correct queue URL. If queue creation fails, an exception should be thrown to prevent the pipeline from starting, ensuring reliability and consistency.

## Installation

The package can be installed by adding `broadway_sqs_init` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:broadway_sqs_init, "~> 0.1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/broadway_sqs_init>.

