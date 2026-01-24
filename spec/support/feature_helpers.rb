# frozen_string_literal: true

module Spec
  module Support
    module FeatureHelpers

      def login(user)
        login_as(user, scope: :user)
        visit root_path
      end

      def logout
        sign_out :user
      end

      def click_on_nav(name)
        within('nav') do
          click_on(name)
        end
      end

      def click_on_table_row_link(text)
        within('table tbody') do
          click_on text
        end
      end

      def click_on_table_row_action(row_text, action:)
        find('tr', text: row_text).find('a', text: action).click
      end

      def click_on_card_action(card_title, action:)
        within_card(card_title) do
          click_on action
        end
      end

      def click_on_submit
        find('input[type=submit], button[type=submit]').click
      end

      def click_on_pagination(page_number)
        within('.pagination, [data-pagination]') do
          click_on page_number.to_s
        end
      end

      def fill_in_date(field, with:)
        fill_in(field, with: with)
        find('body').click
      end

      def select_option(choice, from:)
        select(choice, from: from)
      end

      def tick(label)
        check(label)
      end

      def untick(label)
        uncheck(label)
      end

      def within_card(title, &block)
        within(:xpath, card_xpath(title), &block)
      end

      def within_flash(&block)
        within('.flash, .alert, [data-flash]', &block)
      end

      def within_table_row(row_number:, &block)
        within("table tbody tr:nth-child(#{row_number})", &block)
      end

      def within_table_row_by_text(text, &block)
        within(find('table tbody tr', text: text), &block)
      end

      def within_modal(&block)
        within('.modal, [data-modal]', &block)
      end

      def within_form(title = nil, &block)
        if title
          within(:xpath, form_xpath(title), &block)
        else
          within('form', &block)
        end
      end

      def have_success_message(message = nil)
        if message
          have_css('.alert-success, .flash-success, [data-flash-success]', text: message)
        else
          have_css('.alert-success, .flash-success, [data-flash-success]')
        end
      end

      def have_error_message(message = nil)
        if message
          have_css('.alert-danger, .alert-error, .flash-error, [data-flash-error]', text: message)
        else
          have_css('.alert-danger, .alert-error, .flash-error, [data-flash-error]')
        end
      end

      def have_info_message(message = nil)
        if message
          have_css('.alert-info, .flash-info, [data-flash-info]', text: message)
        else
          have_css('.alert-info, .flash-info, [data-flash-info]')
        end
      end

      def have_card(title)
        have_xpath(card_xpath(title))
      end

      def have_table_row(columns)
        have_css('table tbody tr', text: Array(columns).join)
      end

      def have_empty_table
        have_css('table tbody tr', text: /no.*records|empty|none/i).or(
          have_css('table tbody tr', count: 0)
        )
      end

      def have_badge(text, type: nil)
        if type
          have_css(".badge-#{type}, .badge.bg-#{type}", text: text)
        else
          have_css('.badge', text: text)
        end
      end

      def expect_table_rows(rows_with_columns, count: nil)
        table = first(:table)

        actual_count = count || rows_with_columns.size
        expect(table).to have_css('tbody tr', count: actual_count)

        rows_with_columns.each_with_index do |columns, index|
          expect_table_row(columns, row_number: index + 1)
        end
      end

      def expect_table_row(columns, row_number:)
        within_table_row(row_number: row_number) do
          Array(columns).each do |column_text|
            expect(page).to have_text(column_text)
          end
        end
      end

      def expect_show_field(label, value:)
        expect(page).to have_css('dt, th, label', text: label)
        expect(page).to have_text(value)
      end

      def expect_show_fields(fields)
        fields.each do |label, value|
          expect_show_field(label, value: value)
        end
      end

      def expect_form_error(message)
        expect(page).to have_css('.field_with_errors, .is-invalid, .invalid-feedback', text: message).or(
          have_css('.alert-danger', text: message)
        )
      end

      def expect_pagination(current_page:, total_pages: nil)
        expect(page).to have_css('.pagination .active, [data-pagination] .active', text: current_page.to_s)
        
        if total_pages
          expect(page).to have_css('.pagination a, [data-pagination] a', text: total_pages.to_s)
        end
      end

      def expect_breadcrumbs(crumbs)
        crumbs.each do |crumb|
          expect(page).to have_css('.breadcrumb, [data-breadcrumb]', text: crumb)
        end
      end

      private

      def card_xpath(title)
        ".//div[contains(@class, 'card')][.//h1[text()='#{title}'] or " \
        ".//h2[text()='#{title}'] or " \
        ".//h3[text()='#{title}'] or " \
        ".//h4[text()='#{title}'] or " \
        ".//*[contains(@class, 'card-title')][text()='#{title}']]"
      end

      def form_xpath(title)
        ".//form[.//h1[text()='#{title}'] or " \
        ".//h2[text()='#{title}'] or " \
        ".//legend[text()='#{title}']]"
      end
    end
  end
end
