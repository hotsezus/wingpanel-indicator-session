/*
 * Copyright 2019 elementary, Inc (https://elementary.io)
 *           2011-2015 Tom Beckmann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

/*
 * docs taken from unity indicator-session's
 * src/backend-dbus/org.gnome.SessionManager.EndSessionDialog.xml
 */
public enum Session.Widgets.EndSessionDialogType {
    LOGOUT = 0,
    SHUTDOWN = 1,
    RESTART = 2,
    HIBERNATE = 3,
    HYBRID_SLEEP = 4
}

public class Session.Widgets.EndSessionDialog : Hdy.Window {
    public signal void reboot ();
    public signal void shutdown ();
    public signal void hibernate ();
    public signal void hybrid_sleep ();
    public signal void logout ();
    public signal void cancelled ();

    public EndSessionDialogType dialog_type { get; construct; }

    public EndSessionDialog (Session.Widgets.EndSessionDialogType type) {
        Object (dialog_type: type);
    }

    construct {
        string icon_name, heading_text, button_text, content_text;

        switch (dialog_type) {
            case EndSessionDialogType.LOGOUT:
                icon_name = "system-log-out";
                heading_text = _("Are you sure you want to Log Out?");
                content_text = _("This will close all open applications.");
                button_text = _("Log Out");
                break;
            case EndSessionDialogType.SHUTDOWN:
            case EndSessionDialogType.RESTART:
                icon_name = "system-shutdown";
                heading_text = _("Are you sure you want to Shut Down?");
                content_text = _("This will close all open applications and turn off this device.");
                button_text = _("Shut Down");
                break;
            case EndSessionDialogType.HIBERNATE:
                icon_name = "system-suspend";
                heading_text = _("Are you sure you want to Hibernate?");
                content_text = _("This will save state of session and turn off this device.");
                button_text = _("Hibernate");
                break;
            case EndSessionDialogType.HYBRID_SLEEP:
                icon_name = "system-suspend";
                heading_text = _("Are you sure you want to Hybrid Sleep?");
                content_text = _("This will save state of session and suspend device. If device loses power when in suspend, session will be restored on next boot");
                button_text = _("Hybrid Sleep");
                break;
            default:
                warn_if_reached ();
                break;
        }

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (heading_text);
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);
        primary_label.hexpand = true;
        primary_label.max_width_chars = 50;
        primary_label.wrap = true;
        primary_label.xalign = 0;

        var secondary_label = new Gtk.Label (content_text);
        secondary_label.max_width_chars = 50;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var cancel = new Gtk.Button.with_label (_("Cancel"));

        var confirm = new Gtk.Button.with_label (button_text);
        confirm.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_area.layout_style = Gtk.ButtonBoxStyle.END;
        action_area.margin_top = 16;
        action_area.spacing = 6;

        /*
         * the indicator does not have a separate item for restart, that's
         * why we show both shutdown and restart for the restart action
         * (which is sent for shutdown as described above)
         */
        if (dialog_type == EndSessionDialogType.RESTART) {
            var confirm_restart = new Gtk.Button.with_label (_("Restart"));
            confirm_restart.clicked.connect (() => {
                reboot ();
                destroy ();
            });

            action_area.add (confirm_restart);
        }

        action_area.add (cancel);
        action_area.add (confirm);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 12
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (action_area, 0, 2, 2);

        deletable = false;
        resizable = false;
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        set_keep_above (true);
        set_position (Gtk.WindowPosition.CENTER);
        stick ();
        add (grid);

        cancel.grab_focus ();

        var cancel_action = new SimpleAction ("cancel", null);
        cancel_action.activate.connect (() => {
            cancelled ();
            destroy ();
        });

        cancel.clicked.connect (() => {
            cancel_action.activate (null);
        });

        key_press_event.connect ((event) => {
            if (Gdk.keyval_name (event.keyval) == "Escape") {
                cancel_action.activate (null);
            }

            return false;
        });

        confirm.clicked.connect (() => {
            if (dialog_type == EndSessionDialogType.RESTART || dialog_type == EndSessionDialogType.SHUTDOWN) {
                shutdown ();
            } else if (dialog_type == EndSessionDialogType.HIBERNATE) {
                hibernate ();
            } else if (dialog_type == EndSessionDialogType.HYBRID_SLEEP) {
                hybrid_sleep ();
            } else {
                logout ();
            }

            destroy ();
        });
    }
}
