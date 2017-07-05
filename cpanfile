requires 'DateTime';
requires 'DateTime::Format::Strptime';

# cpan.theopencloset.net
requires 'OpenCloset::Common';    # OpenCloset::Constants::Status

on 'test' => sub {
    requires 'DateTime';
    requires 'Test::More';

    # cpan.theopencloset.net
    requires 'OpenCloset::Calculator::LateFee';
};
