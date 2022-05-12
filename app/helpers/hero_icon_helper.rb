module HeroIconHelper

# <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
#   <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
# </svg>


# <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
#   <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
# </svg>

  BOOK = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
  ICON

  def hero_icon_book
    BOOK
  end

  SHIELD = <<~ICON.html_safe
  <svg xmlns="http://www.w3.org/2000/svg" class="text-white h-6 w-6 inline" fill="white" viewBox="0 0 512 512">
    <path d="M454.915,1.566c-5.563-2.648-12.14-1.898-16.945,1.961c-47.407,38.141-124.532,38.141-171.939,0  c-5.859-4.703-14.203-4.703-20.063,0c-47.407,38.141-124.532,38.141-171.939,0c-4.805-3.859-11.39-4.609-16.945-1.961  C51.53,4.223,48,9.84,48,15.996v288.002c0,92.782,76.086,170.298,203.532,207.369c1.461,0.422,2.961,0.633,4.468,0.633  c1.508,0,3.007-0.211,4.468-0.633C387.914,474.297,464,396.78,464,303.998V15.996C464,9.84,460.469,4.223,454.915,1.566z M80,45.207  c34,17.092,73.953,22.318,111.711,15.787L80,182.861V45.207z M240,474.063c-101-34.61-160-97.159-160-170.065V272h160V474.063z   M240,240h-76.366L240,154.086V240z M240,105.908L120.808,240H80v-9.775L240,55.678V105.908z M272,272h45.211L272,324.745V272z   M272,373.92L359.361,272h50.977L272,423.511V373.92z M432,303.998c0,72.906-59,135.455-160,170.065v-3.158l160-175.18V303.998z   M432,240H272V44.922c49,24.78,111,25.026,160,0.293V240z"/>
  </svg>
  ICON

  def hero_icon_shield
    SHIELD
  end

  JEWEL = <<~ICON.html_safe
  <svg xmlns="http://www.w3.org/2000/svg" class="text-white h-6 w-6 inline" fill="white" viewBox="0 0 512 512">
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

  def hero_icon_jewel
    JEWEL
  end

  BOX = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="text-white h-6 w-6 inline" fill="white" viewBox="0 0 199.177 199.177" stroke-width="2">
      <path d="M199.177,9.523H0v39.128h9.942v141.003h178.309V48.651h10.926
            C199.177,48.651,199.177,9.523,199.177,9.523z M182.02,183.423H16.173V49.685H182.02V183.423z M192.943,42.417H6.231V15.754
            h186.712C192.943,15.754,192.943,42.417,192.943,42.417z"/>
      <path d="M137.299,63.485H60.475v22.167h76.824V63.485z M131.068,79.422H66.71v-9.706h64.358
            C131.068,69.716,131.068,79.422,131.068,79.422z"/>
    </svg>
  ICON

  def hero_icon_box
    BOX
  end

  RECIPE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="text-white h-6 w-6 inline" fill="white" viewBox="0 0 512 512">
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

  def hero_icon_recipe
    RECIPE
  end

  MAP = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
    </svg>
  ICON

  def hero_icon_map
    MAP
  end

  LOCATION_MARKER = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  ICON

  def hero_icon_location_marker
    LOCATION_MARKER
  end

  HOE = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="white" viewBox="0 0 469.99 469.99" stroke="currentColor" stroke-width="2">
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

  def hero_icon_hoe
    HOE
  end

  SEEDLING = <<~ICON.html_safe
    <svg width="24px" class="h-6 w-6 inline" fill="white" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path fill="none" d="M0 0H24V24H0z"/>
      <path d="M6 3c3.49 0 6.383 2.554 6.913 5.895C14.088 7.724 15.71 7 17.5 7H22v2.5c0 3.59-2.91 6.5-6.5 6.5H13v5h-2v-8H9c-3.866 0-7-3.134-7-7V3h4zm14 6h-2.5c-2.485 0-4.5 2.015-4.5 4.5v.5h2.5c2.485 0 4.5-2.015 4.5-4.5V9zM6 5H4v1c0 2.761 2.239 5 5 5h2v-1c0-2.761-2.239-5-5-5z"/>
    </svg>
  ICON

  def hero_icon_seedling
    SEEDLING
  end

  CHAT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
    </svg>
  ICON

  def hero_icon_chat
    CHAT
  end

  KEY = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 inline" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M18 8a6 6 0 01-7.743 5.743L10 14l-1 1-1 1H6v2H2v-4l4.257-4.257A6 6 0 1118 8zm-6-4a1 1 0 100 2 2 2 0 012 2 1 1 0 102 0 4 4 0 00-4-4z" clip-rule="evenodd" />
    </svg>
  ICON

  def hero_icon_key
    KEY
  end

  SIGN_OUT = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
    </svg>
  ICON

  def hero_icon_sign_out
    SIGN_OUT
  end

  SIGN_IN = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
    </svg>
  ICON

  def hero_icon_sign_in
    SIGN_IN
  end

  USER_PLUS = <<~ICON.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
    </svg>
  ICON

  def hero_icon_user_plus
    USER_PLUS
  end
end