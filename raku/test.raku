# This file is a progressive, practical Raku walkthrough:
# config, data cleanup, OO modeling, functional state, concurrency, and cleanup.

# =========================================================
# 1) Basics: environment and timestamps
# =========================================================

# Read runtime environment config via the built-in environment map with a safe fallback.
# Run with override: APP_ENV=production raku test.raku
my $app-environment = %*ENV<APP_ENV> // "development";
my $application-name = "Invoice Processor";
my $script-start-time = DateTime.now;

sub paint(Str $code, Str $text --> Str) {
    "\e[" ~ $code ~ "m" ~ $text ~ "\e[0m"
}

sub money(Str $value --> Str) {
    paint("32", $value)
}

sub flag(Bool $value --> Str) {
    paint($value ?? "32" !! "31", $value.Str)
}

sub section(Str $label --> Nil) {
    say "";
    say paint("35;1", "── " ~ $label ~ " " ~ "─" x 28);
}
# Practical startup log line with a timestamp.
say paint("35", "════════ Raku Workflow Spectacular 🎭 ════════");
say paint("36", "$application-name started at $script-start-time");
say "Running in environment: " ~ paint("33", $app-environment);


# =========================================================
# 2) Practical functions: text and data normalization
# =========================================================
section("Text Cleanup");

# These helpers are pure transformations: same input -> same output.
sub normalize-email(Str $raw-email-address --> Str) {
    # Trim accidental spaces and normalize casing.
    $raw-email-address.trim.lc
}

sub initials(Str $full-name --> Str) {
    # Convert "Ada Lovelace" -> "A L".
    $full-name.words.map({ .comb[0] }).join(" ").uc
}

sub count-vowels(Str $input-text --> Int) {
    # Count vowels in user-facing text (quick text-quality check).
    ($input-text.lc.comb(/<[aeiou]>/)).elems
}

my $raw-customer-email = "  Ada.Lovelace@Example.COM  ";
# Example inputs and outputs for normalized customer data.
say "Normalized email: " ~ paint("36", normalize-email($raw-customer-email));
say "Customer initials: " ~ paint("33", initials("Ada Lovelace"));
say "Vowels in ticket title: " ~ paint("35", count-vowels("Payment failed on checkout").Str);


# =========================================================
# 3) Object-oriented cart: pricing and stock-aware checkout
# =========================================================
section("Cart Checkout");

class CartItem {
    has Str $.name;
    has Real $.unit-price;
    has Int $.requested-quantity;
    has Int $.available-quantity;

    method shippable-quantity(--> Int) {
        # Never ship more than what inventory can fulfill.
        $.requested-quantity min $.available-quantity
    }

    method line-subtotal(--> Real) {
        $.unit-price * self.shippable-quantity
    }
}

class ShoppingCart {
    has Str $.currency-code = "USD";
    has Real $.discount-percent = 0;
    has Real $.tax-rate-percent = 0;
    has CartItem @.items;

    method add-item(CartItem $item --> Nil) {
        @!items.push($item);
    }

    method subtotal(--> Real) {
        [+] @!items.map(*.line-subtotal)
    }

    method total-discount(--> Real) {
        self.subtotal * ($.discount-percent / 100)
    }

    method discounted-subtotal(--> Real) {
        # Business rule: discount is applied before tax.
        self.subtotal - self.total-discount
    }

    method tax-amount(--> Real) {
        self.discounted-subtotal * ($.tax-rate-percent / 100)
    }

    method final-total(--> Real) {
        self.discounted-subtotal + self.tax-amount
    }

    method format-money(Real $amount --> Str) {
        sprintf("%s %.2f", $.currency-code, $amount)
    }
}

my $shopping-cart = ShoppingCart.new(
    discount-percent => 10,
    tax-rate-percent => 8.25,
);
$shopping-cart.add-item(
    CartItem.new(
        name => "Keyboard",
        unit-price => 49.50,
        requested-quantity => 2,
        available-quantity => 1,
    )
);
$shopping-cart.add-item(
    CartItem.new(
        name => "Mouse",
        unit-price => 19.99,
        requested-quantity => 1,
        available-quantity => 3,
    )
);
$shopping-cart.add-item(
    CartItem.new(
        name => "Cable",
        unit-price => 5.00,
        requested-quantity => 3,
        available-quantity => 3,
    )
);

for $shopping-cart.items -> $cart-item {
    say paint("36", $cart-item.name) ~ " -> " ~
        "requested " ~ paint("33", $cart-item.requested-quantity.Str) ~ ", " ~
        "shippable " ~ paint("32", $cart-item.shippable-quantity.Str);
}

my $cart-subtotal = $shopping-cart.subtotal;
my $cart-discount = $shopping-cart.total-discount;
my $cart-tax = $shopping-cart.tax-amount;
my $cart-final-total = $shopping-cart.final-total;

say "Cart subtotal: " ~ money($shopping-cart.format-money($cart-subtotal));
say "Discount amount: " ~ paint("33", $shopping-cart.format-money($cart-discount));
say "Tax amount: " ~ paint("35", $shopping-cart.format-money($cart-tax));
say "Final total: " ~ money($shopping-cart.format-money($cart-final-total));


# =========================================================
# 4) Pure functional example: bank account operations
# =========================================================
section("Account State");

class BankAccountState {
    has Str $.owner;
    has Real $.balance;
}

class WithdrawalResult {
    has Bool $.approved;
    has BankAccountState $.account;
}

sub create-bank-account(Str $owner-name, Real $opening-balance --> BankAccountState) {
    # Build an immutable-style account object.
    BankAccountState.new(owner => $owner-name, balance => $opening-balance)
}

sub deposit-into-account(
    BankAccountState $account,
    Real $deposit-amount
    --> BankAccountState
) {
    # Return a new account object with increased balance.
    BankAccountState.new(
        owner => $account.owner,
        balance => $account.balance + $deposit-amount,
    )
}

sub withdraw-from-account(
    BankAccountState $account,
    Real $withdrawal-amount
    --> WithdrawalResult
) {
    # Return both approval status and a new account value.
    my $withdrawal-approved = $withdrawal-amount <= $account.balance;
    my $next-balance =
        $withdrawal-approved
        ?? ($account.balance - $withdrawal-amount)
        !! $account.balance;

    WithdrawalResult.new(
        approved => $withdrawal-approved,
        account => BankAccountState.new(
            owner => $account.owner,
            balance => $next-balance,
        ),
    )
}

sub account-summary(BankAccountState $account --> Str) {
    # User-readable account status from immutable state.
    sprintf("%s balance: %.2f", $account.owner, $account.balance)
}

my $operations-account = create-bank-account("Operations", 500);
my $account-after-deposit = deposit-into-account($operations-account, 125.50);
my $withdrawal-result = withdraw-from-account($account-after-deposit, 200);
my $final-account-state = $withdrawal-result.account;
my $failed-withdrawal-result = withdraw-from-account($final-account-state, 1000);

say "Vendor payment sent: " ~ flag($withdrawal-result.approved);
say paint("36", account-summary($final-account-state));
say "Large payment approved: " ~ flag($failed-withdrawal-result.approved);
say "Balance after failed payment: " ~
    paint("36", account-summary($failed-withdrawal-result.account));


# =========================================================
# 5) Concurrency: parallel API-style calls
# =========================================================
section("Parallel Fetch");

sub fetch-user-profile(Int $user-id --> Str) {
    # Simulate slower profile service call.
    sleep 0.2;
    "profile:$user-id"
}

sub fetch-user-orders(Int $user-id --> Str) {
    # Simulate faster orders service call.
    sleep 0.1;
    "orders:$user-id"
}

# Kick off both requests in parallel.
my $customer-user-id = 42;
my $profile-fetch-task = start { fetch-user-profile($customer-user-id) };
my $orders-fetch-task = start { fetch-user-orders($customer-user-id) };
# Wait for both responses before combining.
my ($fetched-profile, $fetched-orders) = await $profile-fetch-task, $orders-fetch-task;

say paint("34", "Fetched $fetched-profile and $fetched-orders");

# Class-based async workflow: methods return Promise tasks.
class AsyncCustomerService {
    method fetch-profile-async(Int $user-id --> Promise) {
        start {
            sleep 0.15;
            "class-profile:$user-id"
        }
    }

    method fetch-orders-async(Int $user-id --> Promise) {
        start {
            sleep 0.07;
            "class-orders:$user-id"
        }
    }
}

my $async-customer-service = AsyncCustomerService.new;
my $class-profile-task = $async-customer-service.fetch-profile-async($customer-user-id);
my $class-orders-task = $async-customer-service.fetch-orders-async($customer-user-id);
my ($class-profile, $class-orders) = await $class-profile-task, $class-orders-task;
say paint("34", "Class async fetched $class-profile and $class-orders");


# =========================================================
# 6) Concurrency: use fastest mirror result
# =========================================================
section("Fastest Mirror");

# Simulate two mirror health checks with different response times.
my $slow-mirror-check-task = start { sleep 0.25; "mirror-a: ok" };
my $fast-mirror-check-task = start { sleep 0.05; "mirror-b: ok" };

# Wait until at least one of the tasks completes.
await Promise.anyof($slow-mirror-check-task, $fast-mirror-check-task);

# Pick the completed task's value.
# If the fast task is already Kept, use its result; otherwise use the slow one.
my $fastest-mirror-result =
    $fast-mirror-check-task.status ~~ Kept
    ?? $fast-mirror-check-task.result
    !! $slow-mirror-check-task.result;
say "Fastest health check: " ~ paint("32", $fastest-mirror-result);


# =========================================================
# 7) Concurrency pattern: queue with multiple consumers
# =========================================================
section("Shared Queue");

my $invoice-job-queue = Channel.new;

# Producer adds invoice IDs into the shared queue.
my $job-producer-task = start {
    my @invoice-job-ids = (1001..1010).map({ "invoice-$_" });
    for @invoice-job-ids -> $invoice-id {
        $invoice-job-queue.send($invoice-id);
    }
    # Signal no more jobs.
    $invoice-job-queue.close;
}

# Start one worker that consumes from the shared queue.
# Each job is handled by one worker only (work-sharing / load balancing).
sub start-queue-worker(Str $worker-name, Channel $shared-queue --> Promise) {
    start {
        my @processed-job-results;
        for $shared-queue.list -> $invoice-id {
            # Simulate processing time so workers naturally share the queue.
            sleep 0.02;
            @processed-job-results.push("$worker-name processed:$invoice-id");
        }
        @processed-job-results
    }
}

my $worker-a-task = start-queue-worker("worker-a", $invoice-job-queue);
my $worker-b-task = start-queue-worker("worker-b", $invoice-job-queue);

await $job-producer-task;
my @processed-invoice-results = flat (await $worker-a-task), (await $worker-b-task);
say paint("34", "Queue result: ") ~ @processed-invoice-results.sort.join(", ");


# =========================================================
# 8) Defer equivalent: guaranteed cleanup with LEAVE
# =========================================================
section("Cleanup Hooks");

{
    my $temporary-report-path = "/tmp/raku-report.txt";

    # try keeps the script running after simulated failure in this demo.
    try {
        my $report-file-handle = open $temporary-report-path, :w;

        # LEAVE is Raku's defer-like cleanup hook for scope exit.
        LEAVE {
            $report-file-handle.close if $report-file-handle.defined;
            $temporary-report-path.IO.unlink if $temporary-report-path.IO.e;
            say paint("35", "Cleanup complete for temp report file");
        }

        # Simulate writing a report file.
        $report-file-handle.say("daily-sales,1450.20");
        $report-file-handle.say("daily-refunds,120.00");

        # Simulate crash: LEAVE still runs and cleans up.
        die "Simulated crash after writing report";
    }

    say "Temp report exists after crash? " ~ paint("32", $temporary-report-path.IO.e.Str);
}
