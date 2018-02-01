/*
 * Supersubs v0.2b - jQuery plugin
 * Copyright (c) 2008 Joel Birch
 *
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 * This plugin automatically adjusts submenu widths of suckerfish-style menus to that of
 * their longest list item children. If you use this, please expect bugs and report them
 * to the jQuery Google Group with the word 'Superfish' in the subject line.
 */
(function(e){e.fn.supersubs=function(t){var n=e.extend({},e.fn.supersubs.defaults,t);return this.each(function(){var t=e(this);var r=e.meta?e.extend({},n,t.data()):n;var i=e('<li id="menu-fontsize">&#8212;</li>').css({padding:0,position:"absolute",top:"-999em",width:"auto"}).appendTo(t).width();e("#menu-fontsize").remove();$ULs=t.find("ul");$ULs.each(function(t){var n=$ULs.eq(t);var s=n.children();var u=s.children("a");var a=s.css("white-space","nowrap").css("float");var f=n.add(s).add(u).css({"float":"none",width:"auto"}).end().end()[0].clientWidth/i;f+=r.extraWidth;if(f>r.maxWidth){f=r.maxWidth}else if(f<r.minWidth){f=r.minWidth}f+="em";n.css("width",f);s.css({"float":a,width:"100%","white-space":"normal"}).each(function(){var t=e(">ul",this);var n=t.css("left")!==undefined?"left":"right";t.css(n,f)})})})};e.fn.supersubs.defaults={minWidth:9,maxWidth:25,extraWidth:0}})(jQuery)