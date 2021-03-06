use utf8;
package Shop::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Shop::Schema::Result::Category

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<categories>

=cut

__PACKAGE__->table("categories");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'categories_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 location

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "categories_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "location",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 items

Type: has_many

Related object: L<Shop::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Shop::Schema::Result::Item",
  { "foreign.category_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-26 00:35:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y2d7FMF4P7SpH0E6/0Etgw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
