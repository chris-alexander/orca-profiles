$fn = 96;

/* =========================
   Parameters
   ========================= */

bed_x = 220;
bed_y = 220;

thickness = 1.5;
corner_r  = 1.0;

// Tab (front handle)
tab_depth      = 10;   // mm protrusion
tab_join_width = 100;  // width where it meets bed edge
tab_outer_width = 80;  // width at front edge
tab_front_r     = 4;   // rounding only at front edge/corners

// Label options: "none", "emboss", "engrave"
label_mode  = "engrave";
label_text  = "220x220";
label_size  = 8.0;
label_depth = 1.0;     // used for emboss height or engrave depth
label_y     = -tab_depth/2;


/* =========================
   Helpers
   ========================= */

module rounded_rect_2d(x, y, r) {
    if (r <= 0) square([x, y], center=false);
    else hull() {
        translate([r, r]) circle(r=r);
        translate([x-r, r]) circle(r=r);
        translate([r, y-r]) circle(r=r);
        translate([x-r, y-r]) circle(r=r);
    }
}

module rounded_plate(x, y, z, r) {
    linear_extrude(height=z) rounded_rect_2d(x, y, r);
}

module tab_front_rounded_2d(join_w, outer_w, depth, r) {
    let(
        r_a = min(r, outer_w/2 - 0.01),
        r2  = min(r_a, depth/2 - 0.01)
    )
    if (r2 <= 0) {
        polygon(points=[
            [-join_w/2, 0],
            [ join_w/2, 0],
            [ outer_w/2, -depth],
            [-outer_w/2, -depth]
        ]);
    } else {
        hull() {
            translate([-join_w/2, -0.01])
                square([join_w, 0.02], center=false);

            hull() {
                translate([ outer_w/2 - r2, -depth + r2 ]) circle(r=r2);
                translate([-outer_w/2 + r2, -depth + r2 ]) circle(r=r2);
            }
        }
    }
}

module tab_3d(join_w, outer_w, depth, z, r) {
    linear_extrude(height=z)
        tab_front_rounded_2d(join_w, outer_w, depth, r);
}

module label_shape_2d() {
    text(label_text,
         size=label_size,
         font="DejaVu Sans:style=Bold",
         halign="center",
         valign="center");
}


/* =========================
   Model (centred for Orca)
   ========================= */

translate([-bed_x/2, -bed_y/2, -thickness])
difference() {

    // Main solid
    union() {
        rounded_plate(bed_x, bed_y, thickness, corner_r);

        translate([bed_x/2, 0, 0])
            tab_3d(tab_join_width, tab_outer_width, tab_depth, thickness, tab_front_r);

        if (label_mode == "emboss") {
            translate([bed_x/2, label_y, thickness])
                linear_extrude(height=label_depth)
                    label_shape_2d();
        }
    }

    // Engraved label (subtractive)
    if (label_mode == "engrave") {
        translate([bed_x/2, label_y, thickness - label_depth])
            linear_extrude(height=label_depth + 0.02)
                label_shape_2d();
    }
}
