# frozen_string_literal: true

# Which scenes still need their finds imported (see SceneFindsReport).
class Adm::ScenesController < AdmController
  def index
    authorize(FindsImport, :index?)
    page_title 'Scene Finds'
    report = SceneFindsReport.new(**params.permit(:region, :scene_type, :status, :sort).to_h.symbolize_keys)
    render Views::Adm::Scenes::Index.new(report: report)
  end
end
