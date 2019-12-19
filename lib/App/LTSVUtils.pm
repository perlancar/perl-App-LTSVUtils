package App::LTSVUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my %args_common = (
);

my %arg_filename_0 = (
    filename => {
        summary => 'Input LTSV file',
        schema => 'filename*',
        description => <<'_',

Use `-` to read from stdin.

_
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_filename_1 = (
    filename => {
        summary => 'Input LTSV file',
        description => <<'_',

Use `-` to read from stdin.

_
        schema => 'filename*',
        req => 1,
        pos => 1,
        cmdline_aliases => {f=>{}},
    },
);

$SPEC{ltsvutil} = {
    v => 1.1,
    summary => 'Perform action on a LTSV file',
    'x.no_index' => 1,
    args => {
        %args_common,
        action => {
            schema => ['str*', in=>[
                'dump',
                '2csv',
            ]],
            req => 1,
            pos => 0,
            cmdline_aliases => {a=>{}},
        },
        %arg_filename_1,
    },
    args_rels => {
    },
};
sub ltsvutil {
    my %args = @_;
    my $action = $args{action};

    my $res = "";
    my $i = 0;

    my $fh;
    if ($args{filename} eq '-') {
        $fh = *STDIN;
    } else {
        open $fh, "<", $args{filename} or
            return [500, "Can't open input filename '$args{filename}': $!"];
    }
    binmode $fh, ":encoding(utf8)";

    my $code_getline = sub {
        my $row0 = <$fh>;
        return undef unless defined $row0;
        chomp($row0);
        my $row = {};
        for my $col0 (split /\t/, $row0) {
            $col0 =~ /(.+):(.*)/ or die "Row $i: Invalid column '$col0': must be in LABEL:VAL format\n";
            $row->{$1} = $2;
        }
        $row;
    };

    my $rows = [];
    my %col_idxs;

    while (my $row = $code_getline->()) {
        $i++;
        if ($action eq 'dump') {
            push @$rows, $row;
        } elsif ($action eq '2csv' || $action eq '2tsv') {
            push @$rows, $row;
            for my $k (sort keys %$row) {
                next if defined $col_idxs{$k};
                $col_idxs{$k} = keys(%col_idxs);
            }
        } else {
            return [400, "Unknown action '$action'"];
        }
    } # while getline()

    my @cols = sort { $col_idxs{$a} <=> $col_idxs{$b} } keys %col_idxs;

    if ($action eq 'dump') {
        return [200, "OK", $rows];
    } elsif ($action eq '2csv') {
        require Text::CSV_XS;
        my $csv = Text::CSV_XS->new({binary=>1});
        $csv->print(\*STDOUT, \@cols);
        print "\n";
        for my $row (@$rows) {
            $csv->print(\*STDOUT, [map {$row->{$_} // ''} @cols]);
            print "\n";
        }
    } elsif ($action eq '2tsv') {
        if (@cols) {
            print join("\t", @cols) . "\n";
            for my $row (@$rows) {
                print join("\t", map { $row->{$_} // '' } @cols) . "\n";
            }
        }
    } else {
        return [500, "Unknown action '$action'"];
    }

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
} # ltsvutil

$SPEC{ltsv_dump} = {
    v => 1.1,
    summary => 'Dump LTSV as data structure (array of hashes)',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv_dump {
    my %args = @_;
    ltsvutil(%args, action=>'dump');
}

$SPEC{ltsv2csv} = {
    v => 1.1,
    summary => 'Convert LTSV to CSV',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv2csv {
    my %args = @_;
    ltsvutil(%args, action=>'2csv');
}

$SPEC{ltsv2tsv} = {
    v => 1.1,
    summary => 'Convert LTSV to TSV',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub ltsv2tsv {
    my %args = @_;
    ltsvutil(%args, action=>'2tsv');
}

1;
# ABSTRACT: CLI utilities related to LTSV

=for Pod::Coverage ^(ltsvutil)$

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

# INSERT_EXECS_LIST


=head1 FAQ


=head1 SEE ALSO

L<https://ltsv.org>

L<App::TSVUtils>

L<App::CSVUtils>

L<App::SerializeUtils>

=cut
