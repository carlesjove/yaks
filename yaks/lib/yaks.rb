# -*- coding: utf-8 -*-

require 'forwardable'
require 'set'
require 'pathname'
require 'json'

require 'anima'
require 'concord'
require 'inflection'
require 'uri_template'
require 'rack/accept'

require 'yaks/version'
require 'yaks/util'
require 'yaks/configurable'
require 'yaks/fp'
require 'yaks/fp/callable'
require 'yaks/primitivize'
require 'yaks/attributes'
require 'yaks/stateful_builder'
require 'yaks/errors'

require 'yaks/default_policy'

module Yaks
  Undefined = Module.new.freeze

  # Set the Root constant as the gems root path
  Root = Pathname(__FILE__).join('../..')

  class << self
    # @param [Proc] blk
    # @return [Yaks::Config]
    def new(&blk)
      Yaks::Config.new(&blk)
    end
  end

end


require 'yaks/resource'
require 'yaks/null_resource'
require 'yaks/resource/link'
require 'yaks/collection_resource'

require 'yaks/html5_forms'

require 'yaks/mapper/association'
require 'yaks/mapper/has_one'
require 'yaks/mapper/has_many'
require 'yaks/mapper/attribute'
require 'yaks/mapper/link'
require 'yaks/mapper/form'
require 'yaks/mapper/form/field'
require 'yaks/mapper/config'
require 'yaks/mapper/class_methods'
require 'yaks/mapper'
require 'yaks/mapper/association_mapper'
require 'yaks/collection_mapper'

require 'yaks/resource/form'

require 'yaks/serializer'

require 'yaks/format'
require 'yaks/format/hal'
require 'yaks/format/halo'
require 'yaks/format/json_api'
require 'yaks/format/collection_json'

require 'yaks/config/dsl'
require 'yaks/config'
require 'yaks/runner'
