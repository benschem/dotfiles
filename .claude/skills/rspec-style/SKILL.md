---
name: rspec-style
description: Ben's RSpec conventions and style guide. Use whenever writing, reviewing, or auditing RSpec specs in any Ruby/Rails project — covers describe/context structure, FactoryBot, named subjects and let, matchers, mocking and verified doubles, time-freezing, job/mailer/request/system/service specs, JSON API assertions, and avoiding implementation-coupled or coverage-padding tests.
---

# RSpec conventions

These conventions reflect how I write tests. Apply them strictly.

**When reviewing existing spec(s)**: check them against the conventions below. For each deviation, quote the offending lines and suggest a concrete fix. Group findings by severity (must-fix vs nice-to-have). Don't restate what's already correct.

**When writing new specs** (or when I explicitly ask): follow the same conventions to author the spec.

## Non-Rails projects (Sinatra, plain Ruby, etc.)

This guide is written Rails-first, but the core conventions apply to any Ruby project. When working in Sinatra, Hanami, plain Ruby, or anything else, use common sense to translate the Rails-specific bits:

- `require 'spec_helper'` instead of `rails_helper`, and skip `type:` metadata unless the framework wires it up.
- Use rack-test (`def app; ... end`) for HTTP-level specs rather than Rails request/system specs. The "test at the lowest level that can verify the behaviour" rule still holds.
- Skip the Rails-only sections wholesale when they don't apply: Shoulda Matchers, Devise auth, ActiveStorage, ActionMailer `deliveries`, ActiveJob helpers (`have_enqueued_job`/`have_enqueued_mail`), `response.parsed_body`, `travel_to`/`freeze_time`. Reach for the framework's own equivalents instead (e.g. a plain `Timecop` or stubbed clock, the mailer library's test inbox, the job library's test mode).
- Everything framework-agnostic still stands: behaviour over implementation, FactoryBot, named subjects and `let` over instance variables, `before` for setup, descriptive example names, verified doubles, determinism, one logical assertion per example, no coverage-padding tests.

If translating a Rails convention to another framework is ever ambiguous, ask me rather than guessing.

## Priority Rules

1. Test behaviour, not implementation
2. Don't test framework internals (Ruby, Rails, gems) unless you changed them
3. One logical assertion per example — multiple `expect`s are fine when they verify the same outcome (use `:aggregate_failures`)
4. Keep examples deterministic (freeze time, use fixed values, don't depend on ordering)
5. Use FactoryBot for all test data
6. Use `before` blocks for setup, keep `it` blocks focused on the assertion
7. Use named subjects and `let` blocks, never instance variables
8. Don't write tests just to inflate coverage. Every test should earn its place.
9. If a spec feels complicated to write, the production code is probably doing too much. Suggest a refactor instead of writing a complex spec.
10. The spec should be at the lowest level that can verify the behaviour. Pure logic → model spec. HTTP contract → request spec. Browser/JS flow → system spec. Flag specs that test at a higher level than necessary (e.g. a system spec asserting business logic that belongs in a model spec).

## Common Mistakes to Avoid

- Testing implementation instead of behaviour
- Mirroring the production code structure in the spec
- Creating too much data in factories
- Overusing mocks and stubs
- Deeply nested contexts
- Asserting exact strings unnecessarily
- Writing redundant examples that prove the same thing
- Forgetting to reload records after state changes

## What to Test

- Test behaviour, not implementation. Assert on outcomes and side effects, not which private methods were called or how something works internally. Tests should still pass after a refactor that doesn't change behaviour.
- Don't test Ruby or Rails internals. Things like `has_many` saving associated records, `validates_presence_of` producing an error, or ActiveJob retry mechanics already have their own test suites. Only write tests for behaviour **you've added or modified**.
- Don't write tests for the sake of coverage. Every test should exist because it catches a real bug or documents a meaningful behaviour. If a test would just be restating the implementation line-for-line, skip it.
- Never write tests that only verify FactoryBot is working. Don't test that a factory builds a valid object unless the factory itself is what you're debugging.
- Focus on the public interface. Test public methods, API endpoints, and user-facing flows. Only test private methods indirectly through the public methods that call them.
- For queries and scopes, assert which records are returned, not just the count. `contain_exactly(record_a, record_b)` catches bugs that `expect(results.count).to eq(2)` won't.
- Prefer asserting side effects when the method's job is to change state. Prefer asserting return values when the method is a query. Don't assert both unless both are part of the contract.
- Don't mirror the production code in the spec. If the implementation loops, branches, or transforms data in a certain way, the spec should describe the behaviour from the outside, not duplicate that logic.
- Prefer the simplest spec that proves the behaviour. If two examples prove the same thing, remove one.

## Avoid Implementation Assertions

- Never assert that a specific internal method was called unless that call is the behaviour itself (e.g. enqueuing a job, calling an external API).
- Don't assert intermediate state if the final observable outcome already proves correctness.
- Prefer asserting: database changes, returned values, HTTP responses, visible UI output.
- When behaviour depends on ordering (e.g. a job enqueued after commit), assert the externally visible outcome, not internal callback order.

## Authentication in Specs (Devise)

- For request specs, include Devise test helpers and use `sign_in`:
  ```ruby
  before { sign_in user }
  ```
  This requires `config.include Devise::Test::IntegrationHelpers, type: :request` in a support file.
- For system specs, sign in through the UI or use Warden test helpers:
  ```ruby
  before { login_as(user) }
  ```
  This requires `config.include Warden::Test::Helpers, type: :system` in a support file.
- Create user records with FactoryBot, adding traits for admin vs regular user as needed.

## Writing Descriptions

- Write test descriptions like a human would say them. Keep them plain, short, and natural.
- Don't use emdashes, semicolons, or overly formal phrasing. Write like you're explaining it to a teammate, not writing documentation.
  ```ruby
  # Good
  it 'sends a confirmation email after signup'
  it 'returns the next unanswered question'
  it 'rejects expired invites'

  # Bad - too formal, sounds like AI wrote it
  it 'ensures that the system dispatches a confirmation email upon successful user registration'
  it 'correctly retrieves and returns the subsequent unanswered question — ordered by position'
  ```

## RuboCop

All spec files must pass the project's RuboCop config (rubocop-rspec, rubocop-factory_bot, rubocop-capybara, rubocop-rails, rubocop-performance). Key rules to be aware of:
- `RSpecRails/InferredSpecType` is disabled — always provide explicit `type:` metadata
- Max line length is 120 characters
- Max block length is 30 lines — split large describe/context blocks if needed
- Use `not_to` instead of `to_not`
- Prefer `is_expected.to` over `expect(subject).to` for one-liners
- After writing tests, run `rubocop` on the spec file and fix any offenses

## File Structure

- Always start with `# frozen_string_literal: true`
- `require 'rails_helper'` on line 3 — use this for any spec that touches Rails (models, requests, jobs, mailers, system specs). Use `spec_helper` only for pure-Ruby tests with no Rails dependency (POROs in `lib/` with no `ActiveSupport` etc.).
- One blank line before `RSpec.describe`

## Describe / Context / It

- **`describe` is for the thing under test** (a class, module, or method). **`context` is for the situation or state** the thing is in. Don't use them interchangeably — pick the one that matches what you're naming.
- Always specify `type:` metadata: `type: :model`, `type: :request`, `type: :system`, `type: :job`, `type: :mailer`, `type: :routing`, `type: :policy`
- Group with `describe` blocks by category: `'associations'`, `'validations'`, `'enums'`, `'callbacks'`, `'scopes'`, or method name (`'#method_name'` for instance, `'.method_name'` for class methods)
- Use `context` for conditional scenarios — always start with `"when ..."`, `"with ..."`, or `"without ..."`
- Nest: `RSpec.describe` > `describe` > `context` > `it`. Keep nesting to 3-4 levels max.
- Avoid deeply nested contexts. If the nesting is getting hard to follow, split into separate `describe` blocks instead of adding more `context` layers.

## Naming Examples

- Never start `it` descriptions with "should"
- Use active, present-tense descriptions: `'creates a new Activity'`, `'raises an error'`, `'returns true'`
- For state: `'is invalid without a title'`, `'is valid with a correct difficulty'`
- For side effects: `'increments room.boxes_count when created'`, `'downcases and strips the email address'`

## One Logical Assertion Per Example

- Each `it` block should verify one logical outcome. For unit-level specs that usually means one `expect`. For request, system, or feature specs that exercise a single user action, multiple `expect`s on the resulting state are normal — use `:aggregate_failures` so all failures report at once instead of stopping at the first.
  ```ruby
  it 'returns the user with updated attributes', :aggregate_failures do
    expect(user.name).to eq('Updated')
    expect(user.email).to eq('new@example.com')
  end
  ```
- Prefer `have_attributes` (see Matchers) over multiple `expect`s when you're checking attributes of one object — it's a single matcher and reads more clearly.
- Split into separate `it` blocks only when the assertions verify *different* outcomes, not different facets of the same outcome.

## Test Data

- Use FactoryBot exclusively. Never fixtures, never `Model.new` or `Model.create` directly.
- Use `create()` when persistence is needed, `build()` for unsaved, `build_stubbed()` when you don't need the database at all. Prefer `build_stubbed` for pure domain logic and `build` for validation tests to keep specs fast.
- Use `attributes_for()` when you just need a params hash (common in request specs).
- Use Faker for dynamic test data in factories (e.g., `Faker::Internet.email`, `Faker::Commerce.product_name`). But when the exact value matters for the assertion, use a fixed value instead so the test is readable and deterministic.
- Use factory traits for variations (e.g., `:verified`, `:invalid`, `:with_tags`). Prefer traits over `after(:create)` hooks for optional associations.
- Use `create_list` / `build_list` for multiples, but don't create more records than the test actually needs.
- Keep factories minimal by default. Only include associations that are required for the object to be valid. Add optional associations through traits, not the base factory. Avoid factories that trigger heavy callbacks unless a specific test needs them.

## let / let! / subject

- Always use `let`, `let!`, and `subject` over instance variables (`@var`).
- Use `subject` to define the primary object under test.
- Use named subjects for clarity: `subject(:user) { build(:user) }`, `subject(:request) { get articles_url }`
- Use `let` for lazy-loaded dependencies.
- Use `let!` only when the object must exist before the test runs (e.g., records that need to be in the DB for a query).
- Stack `let!` declarations when setting up complex related data.
- Don't overdo `let`. If a value is only used in one example and isn't referenced elsewhere, a local variable in the `before` block or inline in the factory call is fine. Deeply nested `let` chains that you have to jump around to understand are worse than a bit of repetition.

## described_class

- Always use `described_class` instead of hardcoding the class name inside the spec:
  ```ruby
  subject(:user) { described_class.new(name: 'Ben') }
  ```

## Hooks

- Use `before` blocks for all test setup — prefer this over putting setup inside the `it` block. Keep `it` blocks focused on the expectation only.
  ```ruby
  # Good
  before do
    user.update(email_address: '  TEST@Example.COM ')
    user.validate
  end

  it 'downcases and strips the email address' do
    expect(user.email_address).to eq('test@example.com')
  end

  # Bad — setup mixed into the example
  it 'downcases and strips the email address' do
    user.update(email_address: '  TEST@Example.COM ')
    user.validate
    expect(user.email_address).to eq('test@example.com')
  end
  ```
- Common `before` uses: calling the named subject, performing an action, mutating state, visiting a page
- Avoid `after` by default — transactional fixtures handle most cleanup. Use it only for resources that escape the transaction: created files, env var changes, network stubs, ENV mutations
- Avoid `before(:context)` (also called `before(:all)`) by default — state leaks across examples and breaks isolation. Use it only for genuinely expensive read-only setup (e.g. parsing a large fixture file once) where no example mutates the result

## Shared Examples

- Shared examples and shared contexts are fine — but only extract them when they're **actually reused** across multiple specs. Don't create them preemptively for a single spec.
- When you do use them, define them in the same file if used within one spec, or in `spec/support/shared_examples/` if shared across files.

## Matchers

- Always use `expect()` syntax — never the old `should` syntax
- Use Shoulda Matchers for associations and validations as one-liners:
  ```ruby
  it { is_expected.to have_many(:items).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  it { is_expected.to allow_value('test@example.com').for(:email_address) }
  it { is_expected.not_to allow_value('bad').for(:email_address) }
  it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1) }
  ```
- Multi-line chain formatting for complex shoulda matchers:
  ```ruby
  it do
    expect(user)
      .to have_many(:articles)
      .dependent(:restrict_with_error)
      .with_foreign_key(:author_id)
      .inverse_of(:author)
  end
  ```
- Use `eq()` for equality, `be(true)` / `be(false)` for exact booleans, `be_valid` / `not_to be_valid` for validity
- Use `include()` for collection membership, `contain_exactly()` for exact array matching, `match_array()` for unordered
- Use `be_present`, `be_empty` for presence checks.
- Prefer `be(true)` / `be(false)` over `be_truthy` / `be_falsey` when the return value is actually a boolean
- Request specs: `be_successful`, `have_http_status(:unprocessable_content)`, `redirect_to(path)`
- System specs (Capybara): `have_text()`, `have_button()`, `have_link()`
- Flash: `expect(flash[:notice]).to eq('...')`

### Predicate Matchers

RSpec auto-generates matchers from predicate methods on the object:
- `be_X` calls `X?` — `expect(order).to be_paid` calls `order.paid?`
- `have_X` calls `has_X?` — `expect(user).to have_pending_invitation` calls `user.has_pending_invitation?`

Prefer these over `expect(order.paid?).to be true`. They read better and produce clearer failure messages.

### have_attributes

Cleanest way to assert several attributes of one object — single matcher, single failure message:
```ruby
expect(user).to have_attributes(name: 'Ben', email: 'ben@example.com', role: 'admin')
```
Prefer this over multiple `expect`s with `:aggregate_failures` when you're checking plain attribute values.

### Compound Matchers (`.and` / `.or`)

Combine matchers with `.and` / `.or` to assert multiple things in one expectation:
```ruby
expect(response.body).to include('Order #').and include('shipped')
expect(user).to be_active.and have_attributes(role: 'admin')
expect(value).to be_a(Integer).or be_a(Float)
```
Often a cleaner alternative to `:aggregate_failures` for two related claims on the same value.

### Block Matchers (`change`, `raise_error`, `yield_*`, `output`)

When asserting side effects, always wrap the action inside the expectation block. Never call the action before it:
```ruby
# Good
expect { request }.to change(Article, :count).by(1)

# Bad — action already happened, change won't be detected
request
expect { }.to change(Article, :count).by(1)
```

- `change { record.reload.status }.from('pending').to('processed')` — prefer the `.from(x).to(y)` form when you know both endpoints. It catches bugs that `.by(n)` misses (e.g. wrong starting state).
- Always reload the record when asserting persisted state changes: `change { record.reload.status }`.
- `raise_error(ErrorClass, 'message')` for exceptions.
- **Avoid bare `not_to raise_error`** — it passes for *any* non-raising outcome and hides bugs. If you don't expect an error, assert the positive behaviour instead. If you specifically expect a different class to not be raised, scope it: `not_to raise_error(SpecificError)`.
- `yield_control` / `yield_with_args(x)` / `yield_with_no_args` for methods that take a block:
  ```ruby
  expect { |b| File.open('x', &b) }.to yield_with_args(File)
  ```
- `output('expected').to_stdout` / `.to_stderr` for code that writes to streams (CLIs, loggers).

### Partial Matching

For loose assertions on hashes, arrays, and objects:
- `hash_including(name: 'Ben')` — partial hash match
- `array_including(1, 2)` — collection contains at least these elements
- `a_kind_of(Numeric)`, `an_instance_of(Article)` — duck typing inside other matchers

Useful inside `have_received(:method).with(...)` and JSON response assertions.

## Mocking & Stubbing

- Use `instance_double` / `class_double` for strict verified doubles — never plain `double`. Verified doubles fail loudly if the real class no longer responds to the method (renamed, removed, arity changed). Plain `double` lets stale mocks pass forever, masking the drift. That guarantee is the entire reason to use them — don't downgrade to `double` to silence a verification failure.
- Use `allow(obj).to receive(:method).and_return(value)` for stubs
- Use `receive` / `have_received` for message expectations — prefer spies (`have_received`) over mocks (`expect().to receive`) when possible. Spies let you arrange-act-assert in the natural order; mocks invert it.
- Only mock external dependencies and boundaries. Never mock the object under test.
- Never use `allow_any_instance_of`. If you need to stub something across instances, rethink the design or inject the dependency.
- When a service calls another service, don't mock the inner service unless it performs external IO or the test specifically needs to isolate that boundary. Prefer exercising the real object graph when possible.

## Time-Dependent Tests

- Always freeze time when testing timestamps, expiration logic, or anything time-sensitive. Never compare against `Time.current` without `freeze_time` or `travel_to`.
- Use `travel_to` or `freeze_time` from ActiveSupport::Testing::TimeHelpers.
- Use `be_within(1.second).of(expected_time)` for timestamp comparisons.

## Job & Mailer Assertions

- Use `have_enqueued_job(JobClass).with(args)` to test that a job was enqueued without testing its internals
- Use `have_enqueued_mail(MailerClass, :method)` to test that a mailer was enqueued
- Test job/mailer internals only in their own dedicated specs

## Model Specs

Structure in this order:
1. `subject` block
2. `let` / `let!` blocks
3. `describe 'associations'` with shoulda one-liners
4. `describe 'validations'` with shoulda one-liners. Only test validations that affect behaviour. Don't add a validation spec for every attribute automatically.
5. `describe 'enums'` if applicable
6. `describe 'callbacks'` if applicable
7. `describe 'scopes'` or `describe '.class_method'`
8. `describe '#instance_method'` with `context` blocks for different scenarios

## Request Specs

- Use request specs for controller testing — never use controller specs (they're deprecated)
- Describe blocks named after the HTTP action: `describe 'GET /index'`, `describe 'POST /create'`, `describe 'DELETE /destroy'`
- Use named subject for the request: `subject(:request) { post articles_url, params: { article: params } }`
- Use `attributes_for(:factory)` for params
- Call the named subject in a `before` block, not inside each `it`. The only exception is when you need `expect { request }` to wrap the action for `change` matchers.
  ```ruby
  # Good — subject called in before, it blocks are assertion-only
  context 'with valid parameters' do
    before { request }

    it 'redirects to the article' do
      expect(response).to redirect_to(article_path(Article.last))
    end
  end

  # Good — subject wrapped in expect for change matchers
  context 'with valid parameters' do
    it 'creates a new Article' do
      expect { request }.to change(Article, :count).by(1)
    end
  end

  # Bad — calling subject inside each it block
  it 'redirects to the article' do
    request
    expect(response).to redirect_to(article_path(Article.last))
  end
  ```
- Test both success and failure paths with separate `context` blocks

## System Specs

- Only use system specs when the behaviour genuinely requires browser interaction (JS, complex form flows, multi-page navigation). For everything else, request specs are faster and simpler.
- Use `before` to visit the page and create data.
- Capybara interactions: `visit`, `fill_in`, `click_button`, `click_link`.
- Assert with `expect(page).to have_text(...)`, `have_button(...)`, etc.
- Use `driven_by(:rack_test)` for non-JS specs (fastest); use `:selenium_chrome_headless` or `:cuprite` for JS.
- Never use the legacy `feature` / `scenario` Capybara DSL — use `describe` / `it` with `type: :system`.

## Mailer Specs

- Use `subject(:mail) { described_class.method_name(args) }`
- Test headers (subject, to, from) and body content separately
- For end-to-end mail assertions in request/system specs (i.e. checking what *actually* got sent during a flow), drive the queue and inspect the inbox:
  ```ruby
  perform_enqueued_jobs do
    post signup_url, params: { user: attributes_for(:user) }
  end

  mail = ActionMailer::Base.deliveries.last
  expect(mail.subject).to eq('Welcome')
  expect(mail.to).to eq(['ben@example.com'])
  expect(mail.body.encoded).to include('Confirm your email')
  ```
- `have_enqueued_mail(MailerClass, :method)` only proves the mail was *scheduled*. To assert what's *in* the rendered mail, you need to perform the job and read `ActionMailer::Base.deliveries`.
- Clear the inbox between examples if you don't have transactional cleanup: `ActionMailer::Base.deliveries.clear` in a `before` (Rails handles this by default in test env, but watch out in custom configurations).

## File Uploads & ActiveStorage

- For file upload params in request specs, use `fixture_file_upload`:
  ```ruby
  let(:image) { fixture_file_upload('test.png', 'image/png') }
  # Files live in spec/fixtures/files/ by default
  ```
- For ActiveStorage attachments in factories or setup, attach directly:
  ```ruby
  user.avatar.attach(
    io: File.open(Rails.root.join('spec/fixtures/files/test.png')),
    filename: 'test.png',
    content_type: 'image/png'
  )
  ```
- Assert attachments with `expect(user.avatar).to be_attached` and `expect(user.avatar.filename.to_s).to eq('test.png')`.
- Configure ActiveStorage to use the `:test` service in `config/environments/test.rb` so uploads don't pollute disk.
- Don't test ActiveStorage internals (variant generation, blob persistence) — only that your code attaches and queries correctly.

## External Services

- **Never make real HTTP calls in tests.** Tests must be deterministic, offline-capable, and fast.
- Use **WebMock** to stub at the HTTP layer and fail loudly on unexpected real requests:
  ```ruby
  # spec/support/webmock.rb
  WebMock.disable_net_connect!(allow_localhost: true)

  # in a spec
  before do
    stub_request(:post, 'https://api.example.com/charges')
      .with(body: hash_including(amount: 1000))
      .to_return(status: 200, body: { id: 'ch_123' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
  ```
- Use **VCR** for complex external interactions where recording a real response once is more practical than hand-stubbing. Commit cassettes; scrub credentials.
- For payment/auth/email providers (Stripe, Auth0, Mailgun), use the gem's official test helpers when they exist (e.g. `Stripe::StripeMock`) — they're more accurate than hand-stubs.
- Assert behaviour after the stub fires (e.g. record created, job enqueued), not the stub itself. The stub is plumbing, not the test.

## Job Specs

- Use `subject(:job_name) { described_class.perform_now }` or `described_class.new(args)`
- Use `perform_enqueued_jobs` block when testing jobs that enqueue other jobs

## Service Object Specs

- Test the public `.call` method (or whatever the entry point is).
- Assert on the return value/result object, any state changes, and any external calls (enqueued jobs, sent emails, etc.).
- Don't test private helper methods directly. Exercise them through `.call`.
  ```ruby
  RSpec.describe ProcessRefund, type: :service do
    subject(:result) { described_class.call(order: order) }

    let(:order) { create(:order, :completed) }

    it 'marks the order as refunded' do
      result
      expect(order.reload.state).to eq('refunded')
    end

    it 'enqueues a refund notification email' do
      expect { result }.to have_enqueued_mail(OrderMailer, :refund_confirmation)
    end
  end
  ```

## Edge Cases

- Always test both happy path and error scenarios
- Each error condition gets its own `context` block
- Test boundary conditions: nil values, empty strings, duplicates, expired timestamps, wrong user, etc.
- For error paths, test both the error AND that state wasn't changed

## Determinism and Avoiding Flaky Tests

- Each example must be independent. Never rely on data created in another example or on global seeds.
- In system specs, always use Capybara's built-in waiting matchers (`have_text`, `have_selector`, `have_button`, etc.). Never use `sleep` or assert on raw HTML right after a click.
- Don't rely on database ordering. If your test depends on records coming back in a certain order, the code under test should have an explicit `order` clause. If it doesn't, use `contain_exactly` or `match_array` instead of `eq`.
- Don't hardcode database IDs. Always reference factory-created records through their `let` variables.
- Don't write assertions that depend on Faker randomness. If the exact value matters for the test, use a fixed string.
- Only assert exact strings when they're part of the contract (API responses, specific validation messages you control). Otherwise use partial matching like `include('Invalid email')` so the test doesn't break when someone tweaks copy.

## JSON API Responses

- Use `response.parsed_body` to access parsed JSON (Rails handles the parsing automatically).
- Match on structure with `include` and `match`:
  ```ruby
  expect(response.parsed_body).to include(
    'name' => 'Widget',
    'price' => '19.99'
  )
  ```
- For arrays, use `match` with `include` or `hash_including` for partial matching:
  ```ruby
  expect(response.parsed_body['products']).to include(
    hash_including('name' => 'Widget')
  )
  ```
- Don't assert on the entire response body. Pick the fields that matter.

## Performance

- Prefer `build_stubbed` > `build` > `create`. Only hit the database when the test requires it.
- Prefer request specs over system specs for anything that doesn't need a real browser.
- Keep factory associations minimal. Don't create a full object graph when you only need one record.
- Avoid `create_list` with large counts. If you need "more than one", two or three is usually enough.

## Style

- No comments unless behavior is genuinely non-obvious.
- `pending 'reason'` for tests you want to write but can't yet.
- Blank line between `describe`/`context` blocks.
- No blank lines between grouped one-liner matchers.
- 2-space indentation.
- Keep lines under 120 characters; break long chains vertically.
