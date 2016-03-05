defmodule HexWeb.PackageMetadata do
  use HexWeb.Web, :model

  embedded_schema do
    field :description, :string
    field :licenses, {:array, :string}
    field :links, :map
    field :maintainers, {:array, :string}
    field :contributors, {:array, :string}
  end

  @required_fields ~w(description)
  @optional_fields ~w(licenses links maintainers)

  def changeset(meta, params \\ :empty) do
    cast(meta, params, @required_fields, @optional_fields)
    |> validate_presence(:description)
  end

  defp validate_presence(changeset, field) do
    validate_change changeset, field, fn _, value ->
      is_present = (value |> String.strip |> String.length) > 0
      if is_present, do: [], else: [{field, "can't be blank"}]
    end
  end
end
