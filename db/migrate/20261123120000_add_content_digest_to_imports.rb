# The SHA-256 of an uploaded export file, so the same file uploaded again
# through the API returns the import it made, rather than a second one.
class AddContentDigestToImports < ActiveRecord::Migration[8.1]
  def change
    %i[ recipe_imports item_catalog_imports finds_imports ].each do |table|
      add_column table, :content_digest, :string
      add_index table, :content_digest
    end
  end
end
