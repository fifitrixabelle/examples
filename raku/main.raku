sub paint(Str:D $code, Str:D $text --> Str:D) {
    "\e[" ~ $code ~ "m" ~ $text ~ "\e[0m"
}

sub banner(Str:D $title --> Str:D) {
    paint("35;1", "╭" ~ "─" x 18 ~ " " ~ $title ~ " " ~ "─" x 18 ~ "╮")
}

# One Collatz step: halve evens, triple-and-add-one for odds.
sub collatz-next(Int:D $n --> Int:D) {
    $n %% 2 ?? $n div 2 !! $n * 3 + 1
}

# `gather` builds a sequence by collecting each `take`.
sub collatz-seq(Int:D $start --> Seq:D) {
    gather {
        my $n = $start;
        take $n;

        while $n != 1 {
            $n = collatz-next($n);
            take $n;
        }
    }
}

sub sparkline(Int:D $steps --> Str:D) {
    "#" x ($steps max 1)
}

# Build a plain-text summary row for the output file.
sub plain-row(Int:D $start, @seq --> Str:D) {
    my $steps = @seq.elems - 1;
    my $peak = @seq.max;
    # `^5` means "the first 5 items"; `*-3..*` means "the last 3 items".
    my $preview = @seq.elems > 10
        ?? (@seq[^5].join(" -> ") ~ " -> ... -> " ~ @seq[*-3..*].join(" -> "))
        !! @seq.join(" -> ");

    "start { $start.fmt('%2d') } | steps { $steps.fmt('%3d') } | peak { $peak.fmt('%4d') } | { $preview }"
}

# Build the terminal version of the row with ANSI colors and a small bar.
sub color-row(Int:D $start, @seq, Str:D $bar-color --> Str:D) {
    my $steps = @seq.elems - 1;
    my $peak = @seq.max;
    my $bar = sparkline(($steps div 3) + 1);

    "  start " ~ paint("33", $start.fmt("%2d")) ~
    "  steps " ~ paint("32", $steps.fmt("%3d")) ~
    "  peak " ~ paint("36", $peak.fmt("%4d")) ~
    "  " ~ paint($bar-color, $bar)
}

sub with-writer(IO::Path:D $path, &block --> Nil) {
    my $fh = $path.open: :w;
    LEAVE $fh.?close;
    block($fh);
}


# More intense: more starting numbers, higher values
my Int:D @starts = (7, 9, 11, 13, 17, 19, 27, 31, 41, 63, 97, 101, 127, 171, 231, 255, 319, 381, 511, 777, 999);
# More vivid and varied ANSI color codes
my Str:D @palette = <35 33 32 34 36 31 95 91 92 93 94 96 97 90 30 37 41 42 43 44 45 46 47>;
my IO::Path:D $output = "collatz.txt".IO;


# Add more detailed stats: mean, median, and a simple ASCII graph for each sequence
sub stats-row(@seq) {
    my $mean = (@seq.sum / @seq.elems).round(0.01);
    my $median = @seq.sort[@seq.elems div 2];
    "mean: $mean | median: $median"
}


# Horizontal sparkline: downsample to max 60 points, scale to 1-8 blocks
sub ascii-graph(@seq) {
    my $maxlen = 60;
    my $blocks = <▁ ▂ ▃ ▄ ▅ ▆ ▇ █>;
    my $max = @seq.max;
    my @points = @seq;
    if @points.elems > $maxlen {
        # Downsample: take every Nth point
        my $step = @points.elems / $maxlen;
        @points = (0..^$maxlen).map({ @seq[($_ * $step).Int] });
    }
    return @points.map({
        $max == 0 ?? ' ' !! $blocks[ ($_ / $max * ($blocks.elems-1)).Int ]
    }).join;
}

# `.kv` gives index/value pairs so we can rotate through the color palette.
my @reports = @starts.kv.map(-> $i, $start {
    my @seq = collatz-seq($start).List;
    {
        color => color-row($start, @seq, @palette[$i % @palette.elems]),
        plain => plain-row($start, @seq),
        steps => @seq.elems - 1,
        stats => stats-row(@seq),
        graph => ascii-graph(@seq),
    }
});


my $title = "Raku Collatz Showcase";
say banner($title);
say paint("90", "  hot starts, sorted by flight length");
# Sort by step count so the shorter sequences appear first.

for @reports.sort(*<steps>) -> $r {
    say $r<color>;
    say paint("90", $r<stats>);
    say paint("37", $r<graph>);
    say paint("90", '-' x 60);
}

my $wildest = @reports.max(*<steps>);
say "  longest ride: " ~ paint("33", $wildest<plain>);


with-writer $output, -> $fh {
    $fh.say($title);
    for @reports.sort(*<steps>) -> $r {
        $fh.say($r<plain>);
        $fh.say($r<stats>);
        $fh.say($r<graph>);
        $fh.say('-' x 60);
    }
}
