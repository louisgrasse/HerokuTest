searchable = require './searchable'
Base = require './base'

class Memberships extends Base
  resource: 'memberships'
  @include searchable

module.exports = Memberships