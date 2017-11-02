use strict;
use Test::More 0.98;
use File::Spec;
use lib 't/lib-dbicschema';
use Schema;
use GraphQL::Execution qw(execute);
use Data::Dumper;

use_ok 'GraphQL::Plugin::Convert::DBIC';

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

my $dbic_class = 'Schema';
my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
  sub { $dbic_class->connect('dbi:SQLite:t/test.db') }
);

subtest 'execute pk + deeper query' => sub {
  my $doc = <<'EOF';
{
  blog(id: [1, 2]) {
    id
    title
    tags {
      name
    }
  }
}
EOF
  run_test(
    [
      $converted->{schema}, $doc, $converted->{root_value},
      (undef) x 3, $converted->{resolver},
    ],
    {
      data => {
        blog => [
          {
            id => 1,
            tags => [ { name => "personal" }, { name => "test" } ],
            title => "Hello!",
          },
          {
            id => 2,
            tags => [ { name => "tech" } ],
            title => "Tech",
          }
        ]
      }
    }
  );
};

done_testing;
