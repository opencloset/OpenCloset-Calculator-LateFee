package OrderDetail;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub clothes {
    return 1;
}

sub price {
    return 5000;
}

1;