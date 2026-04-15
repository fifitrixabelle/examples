#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

sub paint {
    my ($code, $text) = @_;
    return "\e[${code}m${text}\e[0m";
}

my @spells = (
    'laser:gain=7,target=mirror-wall',
    'fog:gain=4,target=front-row',
    'bass:gain=9,target=subfloor',
    'glitter:gain=6,target=ceiling-fans',
);

say paint(35, "════════ Perl Regex Spellbook 🧮 ════════");
say "  " . paint(36, 'regexes') . " unpack weird cue strings into stage actions";
say '';

my $total = 0;
for my $index (0 .. $#spells) {
    my ($name, $gain, $target) = $spells[$index] =~ /^([a-z]+):gain=(\d+),target=([a-z-]+)$/;
    $total += $gain;
    my $meter = '▰' x int(($gain + 1) / 2);
    say "  "
        . paint(1, '#' . ($index + 1)) . ' '
        . paint(33, sprintf('%-8s', $name))
        . ' gain=' . paint(32, $gain)
        . ' target=' . paint(36, $target)
        . ' ' . paint(35, $meter);
}

say '';
say '  total charge: ' . paint(32, $total);
