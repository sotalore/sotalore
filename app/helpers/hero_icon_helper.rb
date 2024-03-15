# frozen_string_literal: true

module HeroIconHelper

  SIZES = {
    xs: 'h-4 w-4',
    sm: 'h-5 w-5',
    md: 'h-6 w-6',
    lg: 'h-12 w-12',
    xl: 'h-24 w-24',
  }.with_indifferent_access.freeze

  COLORS = {
    white: 'text-white',
    gray: 'text-gray-500',
    red: 'text-red-500',
    orange: 'text-orange-500',
    yellow: 'text-yellow-500',
    green: 'text-green-500',
    purple: 'text-purple-500',
    current: 'text-current',
  }.with_indifferent_access.freeze

  ICONS = {}.with_indifferent_access

  class << self
    def add_icon(name, svg)
      ICONS[name] = svg
      define_method("icon_#{name}") do |size: :md, color: :current|
        render_icon(name, size: size, color: color)
      end
    end
  end

  def render_icon(name, size: :md, color: :current, css_class: '')
    raise "Invalid icon: #{name}" unless ICONS.key?(name)
    raise "Invalid size: #{size}" unless SIZES.key?(size)
    raise "Invalid color: #{color}" unless COLORS.key?(color)

    svg = ICONS[name]
    size = SIZES[size]
    color = COLORS[color]
    content_tag(:span, svg, class: "inline-flex items-center #{color} #{size} #{css_class}")
  end

# <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
#   <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
# </svg>


# <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
#   <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
# </svg>

  BOOK = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
  ICON
  add_icon :book, BOOK

  SHIELD = <<~ICON.html_safe
  <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="currentColor" viewBox="0 0 512 512">
    <path d="M454.915,1.566c-5.563-2.648-12.14-1.898-16.945,1.961c-47.407,38.141-124.532,38.141-171.939,0  c-5.859-4.703-14.203-4.703-20.063,0c-47.407,38.141-124.532,38.141-171.939,0c-4.805-3.859-11.39-4.609-16.945-1.961  C51.53,4.223,48,9.84,48,15.996v288.002c0,92.782,76.086,170.298,203.532,207.369c1.461,0.422,2.961,0.633,4.468,0.633  c1.508,0,3.007-0.211,4.468-0.633C387.914,474.297,464,396.78,464,303.998V15.996C464,9.84,460.469,4.223,454.915,1.566z M80,45.207  c34,17.092,73.953,22.318,111.711,15.787L80,182.861V45.207z M240,474.063c-101-34.61-160-97.159-160-170.065V272h160V474.063z   M240,240h-76.366L240,154.086V240z M240,105.908L120.808,240H80v-9.775L240,55.678V105.908z M272,272h45.211L272,324.745V272z   M272,373.92L359.361,272h50.977L272,423.511V373.92z M432,303.998c0,72.906-59,135.455-160,170.065v-3.158l160-175.18V303.998z   M432,240H272V44.922c49,24.78,111,25.026,160,0.293V240z"/>
  </svg>
  ICON
  add_icon :shield, SHIELD

  JEWEL = <<~ICON.html_safe
  <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="currentColor" viewBox="0 0 512 512">
    <path d="M504.499,109.901l-102.4-102.4C397.303,2.697,390.793,0,384,0H128c-6.793,0-13.303,2.697-18.099,7.501l-102.4,102.4
      C2.697,114.697,0,121.207,0,128v256c0,6.793,2.697,13.303,7.501,18.099l102.4,102.4C114.697,509.303,121.207,512,128,512h256
      c6.793,0,13.303-2.697,18.099-7.501l102.4-102.4C509.303,397.303,512,390.793,512,384V128
      C512,121.207,509.303,114.697,504.499,109.901z M393.54,35.14l83.319,83.319l-78.268,39.134l-44.186-44.186L393.54,35.14z
      M384,179.2v153.6L332.8,384H179.2L128,332.8V179.2l51.2-51.2h153.6L384,179.2z M369.69,25.6l-38.4,76.8H180.71l-38.4-76.8H369.69
      z M118.46,35.14l39.134,78.268l-44.186,44.186L35.14,118.46L118.46,35.14z M25.6,142.31l76.8,38.4V331.29l-76.8,38.4V142.31z
      M118.46,476.86L35.14,393.54l78.268-39.134l44.186,44.186L118.46,476.86z M142.31,486.4l38.4-76.8H331.29l38.4,76.8H142.31z
      M393.54,476.86l-39.134-78.268l44.186-44.186l78.268,39.134L393.54,476.86z M486.4,369.69l-76.8-38.4V180.71l76.8-38.4V369.69z"
      />
  </svg>
  ICON
  add_icon :jewel, JEWEL

  BOX = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="currentColor" viewBox="0 0 199.177 199.177" stroke-width="2">
      <path d="M199.177,9.523H0v39.128h9.942v141.003h178.309V48.651h10.926
            C199.177,48.651,199.177,9.523,199.177,9.523z M182.02,183.423H16.173V49.685H182.02V183.423z M192.943,42.417H6.231V15.754
            h186.712C192.943,15.754,192.943,42.417,192.943,42.417z"/>
      <path d="M137.299,63.485H60.475v22.167h76.824V63.485z M131.068,79.422H66.71v-9.706h64.358
            C131.068,69.716,131.068,79.422,131.068,79.422z"/>
    </svg>
  ICON
  add_icon :box, BOX

  RECIPE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="currentColor" viewBox="0 0 512 512">
      <g>
        <g>
          <path d="M384.337,0h-30.417h-42.775H201.802H27.219v512h326.701h30.417h100.445V0H384.337z M232.218,30.417h48.508v123.752
                l-24.254-14.734l-24.255,14.734V30.417z M57.636,481.583V30.417h144.165v177.82l54.672-33.213l54.671,33.213V30.417h42.775
                v451.166H57.636z M454.364,481.583h-70.027V30.417h19.806v229.986h30.417V30.417h19.805V481.583z"/>
        </g>
      </g>
      <g>
        <g>
          <rect x="404.143" y="312.557" width="30.417" height="116.883"/>
        </g>
      </g>
    </svg>
  ICON
  add_icon :recipe, RECIPE

  MAP = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
    </svg>
  ICON
  add_icon :map, MAP

  LOCATION_MARKER = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  ICON
  add_icon :location_marker, LOCATION_MARKER

  HOE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="currentColor" viewBox="0 0 469.99 469.99" stroke="currentColor" stroke-width="2">
      <path d="M115.287,281.51c3.034,1.412,6.355,2.181,9.802,2.181c6.217,0,12.063-2.421,16.459-6.818l33.427-33.427
        c1.389-1.389,2.111-3.188,2.182-5.008L379.28,36.315c4.019-4.019,6.231-9.362,6.231-15.046s-2.213-11.027-6.231-15.046
        c-8.298-8.298-21.797-8.296-30.093,0L147.064,208.346c-1.881,0.074-3.671,0.845-5.008,2.182l-33.426,33.427
        c-4.397,4.396-6.818,10.242-6.818,16.459c0,3.767,0.902,7.392,2.58,10.646c-7.326,9.309-11.313,20.719-11.313,32.747
        c0,11.752,3.803,22.914,10.809,32.103c-11.928,14.064-18.759,31.398-19.365,49.512c-0.688,20.588,6.709,39.704,20.83,53.825
        l28.546,28.546c1.407,1.407,3.314,2.197,5.304,2.197s3.896-0.79,5.304-2.197l101.175-101.175c2.929-2.929,2.929-7.678,0-10.606
        L224.469,334.8c-0.002-0.002-7.334-7.334-7.334-7.334c-13.461-13.46-31.66-20.873-51.246-20.873
        c-18.389,0-36.646,6.724-51.201,18.663c-4.293-6.273-6.609-13.681-6.609-21.448C108.079,295.687,110.61,287.959,115.287,281.51z
        M368.673,16.829c2.448,2.448,2.448,6.432,0,8.88L168.258,226.124l-8.879-8.879L359.795,16.829
        C362.241,14.383,366.225,14.381,368.673,16.829z M125.089,268.691c-2.211,0-4.289-0.861-5.854-2.425
        c-1.563-1.563-2.424-3.642-2.424-5.852s0.86-4.289,2.425-5.853l28.123-28.124l11.705,11.705l-28.124,28.124
        C129.377,267.831,127.299,268.691,125.089,268.691z M148.041,400.619c-2.929,2.929-2.929,7.677,0,10.606
        c1.465,1.465,3.385,2.197,5.304,2.197s3.839-0.732,5.304-2.197l60.516-60.516l10.606,10.606l-90.568,90.568l-10.606-10.607
        l8.839-8.839c2.928-2.929,2.929-7.677,0-10.606c-2.928-2.93-7.677-2.929-10.607,0l-8.838,8.838l-2.029-2.029
        c-11.154-11.153-16.994-26.324-16.445-42.717c0.555-16.583,7.559-32.413,19.722-44.575c12.555-12.555,29.559-19.756,46.652-19.756
        c15.579,0,30.012,5.853,40.639,16.479l2.03,2.03L148.041,400.619z"/>
    </svg>
  ICON
  add_icon :hoe, HOE

  SEEDLING = <<~ICON.html_safe
    <svg class="inline" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path fill="none" d="M0 0H24V24H0z"/>
      <path d="M6 3c3.49 0 6.383 2.554 6.913 5.895C14.088 7.724 15.71 7 17.5 7H22v2.5c0 3.59-2.91 6.5-6.5 6.5H13v5h-2v-8H9c-3.866 0-7-3.134-7-7V3h4zm14 6h-2.5c-2.485 0-4.5 2.015-4.5 4.5v.5h2.5c2.485 0 4.5-2.015 4.5-4.5V9zM6 5H4v1c0 2.761 2.239 5 5 5h2v-1c0-2.761-2.239-5-5-5z"/>
    </svg>
  ICON
  add_icon :seedling, SEEDLING

  CHAT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
    </svg>
  ICON
  add_icon :chat, CHAT

  KEY = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M18 8a6 6 0 01-7.743 5.743L10 14l-1 1-1 1H6v2H2v-4l4.257-4.257A6 6 0 1118 8zm-6-4a1 1 0 100 2 2 2 0 012 2 1 1 0 102 0 4 4 0 00-4-4z" clip-rule="evenodd" />
    </svg>
  ICON
  add_icon :key, KEY

  SIGN_OUT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
    </svg>
  ICON
  add_icon :sign_out, SIGN_OUT

  SIGN_IN = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
    </svg>
  ICON
  add_icon :sign_in, SIGN_IN

  USER_PLUS = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
    </svg>
  ICON
  add_icon :user_plus, USER_PLUS

  BADGE_CHECK = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
    </svg>
  ICON
  add_icon :badge_check, BADGE_CHECK

  INFORMATION_CIRCLE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ICON
  add_icon :information_circle, INFORMATION_CIRCLE

  CHEVRON_RIGHT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
    </svg>
  ICON
  add_icon :chevron_right, CHEVRON_RIGHT

  CHEVRON_LEFT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
    </svg>
  ICON
  add_icon :chevron_left, CHEVRON_LEFT

  PENCIL_ALT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
    </svg>
  ICON
  add_icon :pencil_alt, PENCIL_ALT

  TRASH = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg"  class="inline" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
    </svg>
  ICON
  add_icon :trash, TRASH

  WARNING = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
    </svg>
  ICON
  add_icon :warning, WARNING

  ERROR = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m0-10.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.75c0 5.592 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.57-.598-3.75h-.152c-3.196 0-6.1-1.249-8.25-3.286zm0 13.036h.008v.008H12v-.008z" />
    </svg>
  ICON
  add_icon :error, ERROR

  MAGNIFYING_GLASS = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
    </svg>
  ICON
  add_icon :magnifying_glass, MAGNIFYING_GLASS

  PLUS = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
    </svg>
  ICON
  add_icon :plus, PLUS

  QUESTION = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
    </svg>
  ICON
  add_icon :question, QUESTION

  COGS = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
     <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12a7.5 7.5 0 0015 0m-15 0a7.5 7.5 0 1115 0m-15 0H3m16.5 0H21m-1.5 0H12m-8.457 3.077l1.41-.513m14.095-5.13l1.41-.513M5.106 17.785l1.15-.964m11.49-9.642l1.149-.964M7.501 19.795l.75-1.3m7.5-12.99l.75-1.3m-6.063 16.658l.26-1.477m2.605-14.772l.26-1.477m0 17.726l-.26-1.477M10.698 4.614l-.26-1.477M16.5 19.794l-.75-1.299M7.5 4.205L12 12m6.894 5.785l-1.149-.964M6.256 7.178l-1.15-.964m15.352 8.864l-1.41-.513M4.954 9.435l-1.41-.514M12.002 12l-3.75 6.495" />
    </svg>
  ICON
  add_icon :cogs, COGS

  APPLE_ALT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" stroke="currentColor" stroke-width="1.5" fill="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M474.38,192.05c-14.413-36.829-43.215-67.2-80.869-80.423c-40.875-14.34-83.482-6.199-123.938,4.969 c-0.768-22.101,1.101-44.266,4.241-66.149c1.78-12.349,10.301-37.897-10.837-38.771c-17.544-0.728-17.593,22.756-19.301,34.733 c-3.301,22.975-5.251,46.258-4.62,69.483c-9.719-1.618-19.316-5.236-28.996-7.243c-14.437-2.978-29.141-4.839-43.894-4.856 c-28.429,0-56.486,7.534-79.881,23.987c-45.431,31.966-63.122,87.74-62.353,141.328c0.841,58.023,20.49,113.432,53.548,160.758 c14.591,20.895,31.366,40.932,52.1,56.008c20.15,14.647,42.655,21.51,67.087,25.005c10.374,1.498,20.936,1.538,31.277-0.153 c9.031-1.472,17.488-5.284,26.446-6.798c6.766-1.141,16.307,4.184,22.853,5.64c11.16,2.509,22.643,3.027,34.013,1.732 c41.604-4.742,74.565-23.509,101.942-54.973C473.409,387.13,509.291,281.19,474.38,192.05z M446.946,333.962 c-7.696,26.981-19.875,51.647-35.623,74.791c-13.943,20.491-30.104,40.795-50.821,54.794 c-19.026,12.843-44.776,19.859-67.718,17.755c-11.67-1.06-22.295-6.668-33.883-7.769c-12.973-1.221-24.965,5.721-37.614,7.445 c-49.737,6.766-89.018-27.02-115.99-64.464c-33.09-45.95-52.723-100.85-50.854-157.942c1.716-52.318,26.657-106.303,81.112-120.628 c27.24-7.153,55.928-3.042,82.754,3.861c11.613,2.97,23.598,7.793,35.648,8.44c9.274,1.068,19.479-3.172,28.243-5.584 c52.472-14.437,111.547-17.934,148.085,30.104C464.03,219.12,461.521,282.962,446.946,333.962z"></path> <path class="st0" d="M221.561,59.204c1.95-57.344-62.903-66.302-86.04-54.9C141.55,70.436,192.007,71.892,221.561,59.204z" />
    </svg>
  ICON
  add_icon :apple_alt, APPLE_ALT

  PHOTO = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
    </svg>
  ICON
  add_icon :photo, PHOTO

  SWORD = <<~ICON.html_safe
    <svg fill="currentColor" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg" fill="currentColor" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M218.82812,37.17188A3.99843,3.99843,0,0,0,216,36h-.0127l-63.79882.20117a4.00014,4.00014,0,0,0-3.07129,1.45215L75.919,126.26172l-11.4336-11.4336a12.0157,12.0157,0,0,0-16.9707,0L34.8291,127.51465a11.998,11.998,0,0,0,0,16.9707l20.88672,20.88721a4.00445,4.00445,0,0,1,0,5.65674L25.77441,200.9707a12.01393,12.01393,0,0,0,0,16.97071l12.28516,12.28418a11.99918,11.99918,0,0,0,16.96973,0l29.9414-29.94141a3.99971,3.99971,0,0,1,5.65723,0l20.88672,20.8877a12.0157,12.0157,0,0,0,16.9707,0l12.68555-12.68653a11.998,11.998,0,0,0,0-16.9707l-11.43311-11.43311,88.60889-73.19873a4.001,4.001,0,0,0,1.45215-3.07129L220,40.0127A3.9979,3.9979,0,0,0,218.82812,37.17188ZM136.68652,200a3.97264,3.97264,0,0,1-1.17187,2.82812L122.8291,215.51465a4.00621,4.00621,0,0,1-5.6582,0L96.28418,194.62744a11.998,11.998,0,0,0-16.96973,0l-29.9414,29.94092a3.99974,3.99974,0,0,1-5.65723,0L31.43066,212.28418a4.00445,4.00445,0,0,1,0-5.65674l29.94141-29.94092a12.01392,12.01392,0,0,0,0-16.9707l-20.88672-20.8877a3.99854,3.99854,0,0,1,0-5.65624L53.1709,120.48535a4.00681,4.00681,0,0,1,5.6582,0l76.68555,76.68653A3.97264,3.97264,0,0,1,136.68652,200Zm75.11817-98.08984-87.74951,72.48877L105.65662,156l57.1715-57.17188a3.99957,3.99957,0,1,0-5.65624-5.65624l-57.17176,57.17138L81.60156,131.94434l72.48828-87.749,57.89746-.18261Z"></path>
    </svg>
  ICON
  add_icon :sword, SWORD

  WRENCH = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75a4.5 4.5 0 01-4.884 4.484c-1.076-.091-2.264.071-2.95.904l-7.152 8.684a2.548 2.548 0 11-3.586-3.586l8.684-7.152c.833-.686.995-1.874.904-2.95a4.5 4.5 0 016.336-4.486l-3.276 3.276a3.004 3.004 0 002.25 2.25l3.276-3.276c.256.565.398 1.192.398 1.852z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M4.867 19.125h.008v.008h-.008v-.008z" />
    </svg>
  ICON
  add_icon :wrench, WRENCH


  FIRE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0112 21 8.25 8.25 0 016.038 7.048 8.287 8.287 0 009 9.6a8.983 8.983 0 013.361-6.867 8.21 8.21 0 003 2.48z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 18a3.75 3.75 0 00.495-7.467 5.99 5.99 0 00-1.925 3.546 5.974 5.974 0 01-2.133-1A3.75 3.75 0 0012 18z" />
    </svg>
  ICON
  add_icon :fire, FIRE

  HOME = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
    </svg>
  ICON
  add_icon :home, HOME

  BONE = <<~ICON.html_safe
    <svg fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" stroke="currentColor" class="inline">
      <path d="M19.839,4.161a4.2,4.2,0,1,0-7.658,3.223l-4.8,4.8a4.2,4.2,0,0,0-5.153,6.567,4.163,4.163,0,0,0,1.93,1.091,4.2,4.2,0,1,0,7.658-3.223l4.8-4.8a4.2,4.2,0,1,0,3.224-7.658Zm.515,5.621a2.253,2.253,0,0,1-3.116,0,1,1,0,0,0-1.414,0L9.783,15.824a1,1,0,0,0,0,1.414,2.2,2.2,0,1,1-3.748,1.674,1,1,0,0,0-.946-.947,2.2,2.2,0,1,1,1.673-3.748,1,1,0,0,0,1.414,0l6.041-6.041a1,1,0,0,0,0-1.414,2.2,2.2,0,1,1,3.748-1.674,1,1,0,0,0,.946.947,2.187,2.187,0,0,1,1.443.631h0a2.2,2.2,0,0,1,0,3.116Z" />
    </svg>
  ICON
  add_icon :bone, BONE

  FLASK = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23-.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5" />
    </svg>
  ICON
  add_icon :flask, FLASK

  RECTANGLES = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 7.125C2.25 6.504 2.754 6 3.375 6h6c.621 0 1.125.504 1.125 1.125v3.75c0 .621-.504 1.125-1.125 1.125h-6a1.125 1.125 0 01-1.125-1.125v-3.75zM14.25 8.625c0-.621.504-1.125 1.125-1.125h5.25c.621 0 1.125.504 1.125 1.125v8.25c0 .621-.504 1.125-1.125 1.125h-5.25a1.125 1.125 0 01-1.125-1.125v-8.25zM3.75 16.125c0-.621.504-1.125 1.125-1.125h5.25c.621 0 1.125.504 1.125 1.125v2.25c0 .621-.504 1.125-1.125 1.125h-5.25a1.125 1.125 0 01-1.125-1.125v-2.25z" />
    </svg>
  ICON
  add_icon :rectangles, RECTANGLES

  ARROW_RIGHT_CIRCLE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12.75 15l3-3m0 0l-3-3m3 3h-7.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ICON
  add_icon :arrow_right_circle, ARROW_RIGHT_CIRCLE

  EXTERNAL_LINK = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
    </svg>
  ICON
  add_icon :external_link, EXTERNAL_LINK

  USER_GROUP = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
    </svg>
  ICON
  add_icon :user_group, USER_GROUP

  EYE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  ICON
  add_icon :eye, EYE

  EYE_SLASH = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="inline">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
    </svg>
  ICON
  add_icon :eye_slash, EYE_SLASH
end

