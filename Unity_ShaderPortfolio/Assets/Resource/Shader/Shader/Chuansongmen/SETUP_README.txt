Portal Glitch Pack (URP)

Hierarchy:
PortalRoot
 ├─ PortalFrame          (your model)
 ├─ PortalMaskQuad       (Quad, scale ~ 2,2,1)
 ├─ PortalSurfaceQuad    (Quad, same size, push 0.01 inward)
 ├─ PortalRimQuad        (Quad, same size or 1.04x, pull 0.002 outward)
 └─ PortalTunnel         (Cylinder, rotate X=90, move inward on local Z)

Suggested local transforms:
- MaskQuad      : Pos (0,0,0),      Rot (0,0,0),   Scale (2,2,1)
- SurfaceQuad   : Pos (0,0,0.01),   Rot (0,0,0),   Scale (2,2,1)
- RimQuad       : Pos (0,0,-0.002), Rot (0,0,0),   Scale (2.06,2.06,1)
- TunnelCylinder: Pos (0,0,1.2),    Rot (90,0,0),  Scale (0.9,1.5,0.9)

Materials:
- M_PortalMask         -> TA/Portal/PortalMask
- M_PortalSurface      -> TA/Portal/PortalSurfaceGlitch
- M_PortalTunnel       -> TA/Portal/PortalTunnelGlitch
- M_PortalRim          -> TA/Portal/PortalRimGlow

Recommended starting values:
Mask:
- Radius 0.46
- Edge Softness 0.03
- Stencil Ref 2

Surface:
- Color A (0.08, 0.85, 1.00, 1)
- Color B (0.80, 0.15, 1.00, 1)
- Brightness 2.2
- Swirl Speed 1.8
- Swirl Tiling 7.0
- Glitch Amount 0.65
- Line Density 180
- RGB Split 0.9
- Radius 0.46
- Edge Softness 0.04
- Pulse Speed 3.2
- Stencil Ref 2

Tunnel:
- Color (0.20, 0.90, 1.00, 1)
- Brightness 2.5
- Scroll Speed 1.6
- Stripe Tiling 12
- Twist Amount 8
- Glitch Amount 0.5
- Fade Start 0.65
- Fade Length 0.30
- Opacity 1.0
- Stencil Ref 2

Rim:
- Color (1.00, 0.30, 1.00, 1)
- Intensity 4.0
- Inner Radius 0.42
- Outer Radius 0.50
- Softness 0.03
- Pulse Speed 4.0
- Segment Count 18
- Breakup 0.35

Common fixes:
1) Nothing visible:
   - Surface/Tunnel Stencil Ref must match Mask Stencil Ref.
   - Surface must sit slightly behind Mask, not in front.
   - Make sure the project uses URP.

2) Tunnel looks wrong:
   - Cylinder needs rotation X=90.
   - Imported tunnel mesh should have cylindrical UVs.

3) Portal too flat:
   - Increase tunnel length (scale Y on the rotated cylinder).
   - Raise Tunnel Brightness and lower Fade Start slightly.
