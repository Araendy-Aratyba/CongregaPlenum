# frozen_string_literal: true

module CongregaPlenum
  # One validated catalogue page. Repeated identities remain in source order.
  CatalogPage = Data.define(:records, :next_page) do
    # Validates the API envelope and extracts sequential pagination metadata.
    def self.parse(response, page:)
      records = records_from(response)
      links = links_from(response)
      next_page = continuation(links, page)
      raise APIError, 'empty catalogue page cannot continue' if next_page && records.empty?

      new(records: records.freeze, next_page: next_page)
    end

    def self.records_from(response)
      records = response['dados']
      return records if records.is_a?(Array) && records.all?(Hash)

      raise APIError, 'catalogue page requires an explicit list of objects in dados'
    end
    private_class_method :records_from

    def self.links_from(response)
      links = response['links']
      return links if links.is_a?(Array) && links.all? { |link| link.is_a?(Hash) && link['rel'].is_a?(String) }

      raise APIError, 'catalogue page requires pagination links'
    end
    private_class_method :links_from

    def self.continuation(links, page)
      next_links = links.select { |link| link['rel'] == 'next' }
      return if next_links.empty?

      unless next_links.one? && page_parameter(next_links.first['href']) == [(page + 1).to_s]
        raise APIError, 'invalid catalogue page continuation'
      end

      page + 1
    end
    private_class_method :continuation

    def self.page_parameter(href)
      return [] unless href.is_a?(String)

      query = URI.parse(href).query.to_s
      URI.decode_www_form(query).filter_map { |name, value| value if name == 'pagina' }
    rescue URI::InvalidURIError, ArgumentError
      raise APIError, 'invalid catalogue page continuation'
    end
    private_class_method :page_parameter
  end
end
