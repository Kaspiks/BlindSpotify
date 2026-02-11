# frozen_string_literal: true

module FormHelper
  # Converts a form object name to a DOM-safe id: "foo[bar]" → "foo_bar"
  def object_id_for_name(object_id)
    object_id.gsub(/[\]\[]+/, "_").sub(/_$/, "")
  end

  # Shorthand for rendering a Tom Select-powered association select.
  #
  #   = form_tom_select_field f, :playlist,  collection: @playlists
  #   = form_tom_select_field f, :categories  # uses object.categories_collection_for_select
  #
  def form_tom_select_field(form, association_name, *args, **kwargs)
    plural_name = association_name.to_s.pluralize
    is_multiple = association_name.to_s == plural_name

    collection = kwargs.delete(:collection)
    collection ||= if form.object.respond_to?("#{plural_name}_collection_for_select")
                     form.object.public_send("#{plural_name}_collection_for_select")
                   else
                     []
                   end

    form.association(
      association_name,
      *args,
      **{
        as: :tom_select,
        collection: collection,
        input_html: { multiple: is_multiple }
      }.deep_merge(kwargs)
    )
  end
end
