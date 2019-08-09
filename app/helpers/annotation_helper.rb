module AnnotationHelper
  def annotations_by_type(annotations, type)
    annotations.select {|anno| anno.type == type}
  end

  def one_annotation_by_type(annotations, type)
    annotation = annotations_by_type(annotations, type).first
    annotation ? annotation.value : nil
  end
end