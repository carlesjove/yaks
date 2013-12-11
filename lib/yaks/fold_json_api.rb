# -*- coding: utf-8 -*-

module Yaks
  class FoldJsonApi
    include Concord.new(:collection)
    include Util
    extend Forwardable

    def_delegator :collection, :root_key

    def self.call(collection)
      new(collection).fold
    end

    def fold
      if collection.empty?
        {}
      else
        {
          root_key => collection.map(& λ(:fold_object) ),
          "linked" => fold_associated_objects
        }
      end
    end
    alias call fold

    private

    def fold_object(object)
      if object.has_associated_objects?
        object.attributes.merge(Hamster.hash(links: link_ids(object)))
      else
        object.attributes
      end
    end

    def link_ids(object)
      object.associations.reduce(
        Hamster.hash,
        &method(:fold_association_ids)
      )
    end

    def fold_association_ids(hash, association)
      if association.one?
        hash.put(association.name, association.identities.first)
      else
        hash.put(association.name, association.identities)
      end
    end

    def fold_associated_objects
      association_names = Hamster.set(*
        collection.flat_map do |object|
          object.associations.map{|ass| [ass.name, ass.one?] }
        end
      )
      Hamster.hash(
        association_names.map do |name, one|

          objects = collection.flat_map do |object|
            object.associated_objects(name)
          end

          [
            one ? pluralize(name.to_s) : name,
            Hamster.set(*objects).map(& λ(:fold_object) )
          ]
        end
      )
    end
  end
end
