package Order;

use OrderDetail;

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    while ( my ( $key, $value ) = each %args ) {
        $self->{$key} = $value;
    }

    bless $self, $class;
    return $self;
}

sub target_date {
    my ( $self, $dt ) = @_;
    return $self->{target_date} unless $dt;
    return $self->{target_date} = $dt;
}

sub user_target_date {
    my ( $self, $dt ) = @_;
    return $self->{user_target_date} unless $dt;
    return $self->{user_target_date} = $dt;
}

sub return_date {
    my ( $self, $dt ) = @_;
    return $self->{return_date} unless $dt;
    return $self->{return_date} = $dt;
}

sub order_details {
    my $self = shift;
    my @details;
    for ( 1 .. 5 ) {
        push @details, OrderDetail->new;
    }

    return @details;
}

sub status_id { 1 }
sub online    { 0 }

1;
