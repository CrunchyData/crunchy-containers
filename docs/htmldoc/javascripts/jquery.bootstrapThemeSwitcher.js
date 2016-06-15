/**
* jQuery Twitter Bootstrap Theme Switcher v1.1.5
* https://github.com/jguadagno/bootstrapThemeSwitcher
*
* Copyright 2014, Joseph Guadagno
* Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
*/
;(function ($, window, document, undefined) {

    "use strict";

    var old = $.fn.bootstrapThemeSwitcher;

    // Constructor
    var BootstrapThemeSwitcher = function (element, options) {

        this.$element = $(element);
        this.settings = $.extend({}, $.fn.bootstrapThemeSwitcher.defaults, options);
        this.themesList = [];
        this.getThemes();

        return this;
    };

    // Prototype
    BootstrapThemeSwitcher.prototype = {
        clear: function () {
            console.log('bootstrapThemeSwitcher.clear');
            return this.$element.each(function () {
                this.$element.empty();
            });
        },
        update: function () {
            console.log('bootstrapThemeSwitcher.update');
            this.getThemes();
        },
        switchTheme: function (name, cssFile) {
            console.log('bootstrapThemeSwitcher.switchTheme: name: "' + name + '", cssFile: "' + cssFile + '"');
            var $this = $(this);
            var settings = $.extend({}, $.fn.bootstrapThemeSwitcher.defaults, $this.data('bootstrapThemeSwitcher'));

            var id = settings.cssThemeLink;

            if (cssFile === undefined) {
                cssFile = this.settings.defaultCssFile;
            }
            if (name === undefined) {
                name = cssFile;
            }

            // Remove any existing bootstrap stylesheet that are not the theme ones
            $('head link[href*="bootstrap.min.css"][id!="' + id + '"]').remove();

            // Replace the theme file
            var selector = '#' + id;
            var cssLink = $(selector);
            if (cssLink.length === 0) {
                var cssLinkHtml = "<link rel='stylesheet' id='" + id + "' href='" + cssFile + "' type='text/css' />";
                var firstCssLink = $('head link[rel="stylesheet"]:first');
                if (firstCssLink.length === 0) {
                    $('head').append(cssLinkHtml);
                } else {
                    firstCssLink.before(cssLinkHtml);
                }
                cssLink = $(selector);
            }
            cssLink.attr('href', cssFile);

            // check to see if they want it to be saved
            if (settings.saveToCookie) {
                if ($.cookie === undefined) {
                    console.warn('bootstrapThemeSwitcher: saveToCookie is set to true but jQuery.cookie is not present');
                    return;
                }
                $.cookie(settings.cookieThemeName, name, { expires: settings.cookieExpiration, path: settings.cookiePath });
                $.cookie(settings.cookieThemeCss, cssFile, { expires: settings.cookieExpiration, path: settings.cookiePath });
            }
        },
        loadThemeFromCookie: function (options) {
            if ($.cookie === undefined) {
                console.warn('bootstrapThemeSwitcher: loadThemeFromCookie was called but jQuery.cookie is not present');
                return;
            }
            var settings = $.extend({}, $.fn.bootstrapThemeSwitcher.defaults, options);
            var themeName = $.cookie(settings.cookieThemeName);
            var themeCss = $.cookie(settings.cookieThemeCss);
            this.switchTheme(themeName, themeCss);

        },
        addTheme: function(name, cssFile, start, deleteCount) {
            if (start === undefined) {
                start == 0;
            }
            if (deleteCount === undefined) {
                deleteCount == 0;
            }
            this.themesList.splice(start, deleteCount, {name: name, cssCdn: cssFile});
            this.addThemesToControl();
        },
        addThemesToControl: function() {

            if (this.$element === undefined) {
                console.error('bootstrapThemeSelector: addThemesToControl: Element is undefined');
                return;
            }

            if (this.themesList === undefined) {
                console.error('bootstrapThemeSelector: addThemesToControl: Themes is undefined');
                return;
            }

            //If BootSwatch exclusions are set
            if(this.settings.excludeBootswatch){
              //Split the string on ,
              if(this.settings.excludeBootswatch.indexOf(",") !== -1){
                var excludeBootswatchs = this.settings.excludeBootswatch.split(',');
              }else{
                var excludeBootswatchs = [];
                excludeBootswatchs.push(this.settings.excludeBootswatch);
              }

              var tempThemeList = this.themesList;
              $.each(tempThemeList, function (i, value) {
                if(value && value.name){
                  if( jQuery.inArray( value.name, excludeBootswatchs ) !== -1 ){
                    tempThemeList.splice(i,1);
                  }
                }
              });
              this.themesList = tempThemeList;
            }

            var base = this;

            if (this.$element.is('ul')) {

                console.log('bootstrapThemeSelector: UL element selected');
                this.$element.empty();

                var cssClass;
                $.each(this.themesList, function (i, value) {
                    //Add a class of "active" to the current BootSwatch
                    cssClass = null;
                    if(value.name === $.cookie('bootstrapTheme.name')){
                      cssClass = "active";
                    }
                    var li = $("<li />")
                        .attr("class",cssClass)
                        .append("<a href='#'>" + value.name + "</a>")
                        .on('click', function () {
                            base.switchTheme(value.name, value.cssCdn);

                            //Remove previous "active" class and apply to latest clicked element
                            $(this).parent().find("li").removeClass("active");
                            $(this).addClass("active");
                        });
                    base.$element.append(li);
                });

            } else if (this.$element.is('select')) {
                console.log('bootstrapThemeSelector: SELECT element selected');
                this.$element.empty();

                var optionSelectedMarker;
                $.each(this.themesList, function (i, value) {
                    optionSelectedMarker = null;
                    if(value.name === $.cookie('bootstrapTheme.name')){
                      optionSelectedMarker = "selected";
                    }
                    base.$element.append("<option " + optionSelectedMarker + " value='" + value.cssCdn + "'>" + value.name + "</option>");
                });
                this.$element.on('change', function () {
                    var optionSelected = $("option:selected", this);
                    base.switchTheme(optionSelected.text(), optionSelected.val());
                });

            } else {
                console.warn('bootstrapThemeSelector only works with ul or select elements');
            }
        },

        getThemes: function() {

            var base = this;

            if (this.settings.localFeed !== null && this.settings.localFeed !== '') {
                // Get the file

                $.ajax({
                    url: this.settings.localFeed,
                    async: false,
                    dataType: 'json',
                    success: function (data) {
                        base.themesList = data.themes;
                        base.addThemesToControl();
                    },
                    error: function (jqXHR, textStatus, errorThrown) {
                        console.error("Failed to retrieve the local feed from '" + base.settings.localFeed + "'")
                    }

                });
                return;
            }

            $.ajax({
                url: this.settings.bootswatchApiUrl + "/" + this.settings.bootswatchApiVersion,
                async: false,
                dataType: 'json',
                success: function (data) {
                    if (data.themes === undefined) {
                        return null;
                    }
                    base.themesList = data.themes;
                    base.themesList.splice(0,0, {name: 'default',cssCdn: base.settings.defaultCssFile});

                    base.addThemesToControl();
                }
            });
        },
        themes : function (newThemeList) {
            if (newThemeList === undefined) {
                return this.themesList;
            }
            else {
                // TODO: Set the associated control.
                this.themesList = newThemeList;
            }
        }
    };


    // Plugin
    $.fn.bootstrapThemeSwitcher = function (option) {
        var args = Array.prototype.slice.call(arguments, 1);
        var methodReturn;

        var $this = $(this);
        var data = $this.data('bootstrapThemeSwitcher');
        var options = typeof option === 'object' && option;

        if (!data) {
            $this.data('bootstrapThemeSwitcher', (data = new BootstrapThemeSwitcher(this, options) ));
        }
        if (typeof option === 'string') {
            methodReturn = data[ option ].apply(data, args);
        }
        return ( methodReturn === undefined ) ? $this : methodReturn;
    };

    $.fn.bootstrapThemeSwitcher.defaults = {
        cssThemeLink: 'bootstrapTheme',
        saveToCookie: true,
        cookieThemeName: 'bootstrapTheme.name',
        cookieThemeCss: 'boostrapTheme.css',
        cookieExpiration: 7,
        cookiePath: '/',
        defaultCssFile: '//netdna.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css',
        bootswatchApiUrl: 'http://api.bootswatch.com',
        bootswatchApiVersion: '3',
        loadFromBootswatch: true,
        localFeed: '',
        excludeBootswatch:''
    };

    $.fn.bootstrapThemeSwitcher.Constructor = BootstrapThemeSwitcher;

    $.fn.bootstrapThemeSwitcher.noConflict = function () {
        $.fn.BootstrapThemeSwitcher = old;
        return this;
    };
})(jQuery, window, document);
