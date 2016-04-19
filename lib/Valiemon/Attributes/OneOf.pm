package Valiemon::Attributes::OneOf;
use strict;
use warnings;
use utf8;
use parent qw(Valiemon::Attributes);

use Carp qw(croak);
use List::MoreUtils qw(one);

use Valiemon::Context;

sub attr_name { 'oneOf' }

sub is_valid {
    my ($class, $context, $schema, $data) = @_;

    my $oneOf = $schema->{oneOf};
    if (ref $oneOf ne 'ARRAY' || scalar @$oneOf < 1) {
        croak sprintf '`oneOf` must be an array and have at least one element at %s', $context->position
    }

    my $idx = 0;
    my $errors = [];
    # Clone context to avoid influencing sub_validator's error to main context.
    my $is_valid = one {
        my $clone_context = Valiemon::Context->clone_from($context);
        my ($is_partially_valid, $error) = $clone_context->in_attr($class, sub {
            my $sub_v = $clone_context->sub_validator($_);
            $clone_context->in(
                $idx++, sub { $sub_v->validate($data, $clone_context); }
            );
        });
        # If an error occured keep it so that main context will return it as main context's validation error.
        if ($error) {
            push @$errors, $error;
        }
        $is_partially_valid;
    } @$oneOf;

    unless ($is_valid) {
        return (0, $errors->[0]) if scalar @$errors;

        # If all of validation succeeds, there're no error to return.
        # so run dummy validation to generate error.
        return $context->in_attr($class, sub { return 0; });
    }
    return 1;
}

1;
