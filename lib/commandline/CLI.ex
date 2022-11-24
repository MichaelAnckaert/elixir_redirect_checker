defmodule Commandline.CLI do
  def main(args) do
    options = [switches: [filename: :string], aliases: [f: :filename]]
    {opts, _, _} = OptionParser.parse(args, options)

    [{:filename, filename}] = opts

    read_csv(filename)
  end

  def read_csv(filename) do
    File.stream!(filename)
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.split(&1, ","))
    |> Stream.map(&get_response/1)
    |> Stream.map(&verify_response/1)
    |> Enum.map(fn result -> IO.inspect(result) end)
  end

  def get_response([from_url, to_url]) do
    response = HTTPoison.get!(from_url)

    location_header = Enum.find(response.headers, nil, fn r -> elem(r, 0) == "Location" end)

    redirect_to =
      case location_header do
        {"Location", loc} -> loc
        nil -> nil
      end

    {redirect_to, from_url, to_url}
  end

  def verify_reponse({nil, from_url, to_url}) do
    %{result: :no_match, from_url: from_url, to_url: to_url, redirect_to: nil}
  end

  def verify_response({redirect_to, from_url, to_url}) do
    if redirect_to == to_url do
      %{result: :match, from_url: from_url, to_url: to_url}
    else
      %{result: :no_match, from_url: from_url, to_url: to_url, redirect_to: redirect_to}
    end
  end
end
