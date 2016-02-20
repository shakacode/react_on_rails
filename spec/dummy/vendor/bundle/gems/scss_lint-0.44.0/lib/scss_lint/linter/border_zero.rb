module SCSSLint
  # Enforce a particular value for empty borders.
  class Linter::BorderZero < Linter
    include LinterRegistry

    CONVENTION_TO_PREFERENCE = {
      'zero' => %w[0 none],
      'none' => %w[none 0],
    }.freeze

    BORDER_PROPERTIES = %w[
      border
      border-top
      border-right
      border-bottom
      border-left
    ].freeze

    def visit_root(_node)
      @preference = CONVENTION_TO_PREFERENCE[config['convention']]
      yield # Continue linting children
    end

    def visit_prop(node)
      return unless BORDER_PROPERTIES.include?(node.name.first.to_s)
      check_border(node, node.value.to_sass.strip)
    end

  private

    def check_border(node, border)
      return unless %w[0 none].include?(border)
      return if @preference[0] == border

      add_lint(node, "`border: #{@preference[0]}` is preferred over " \
                     "`border: #{@preference[1]}`")
    end
  end
end
