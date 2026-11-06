#!/bin/sh

rm -f *.beam
elixirc validation.exs graph.exs output.exs routepath.exs search.exs reach.exs connection.exs tool.exs
elixir exec.exs
rm -f *.beam
