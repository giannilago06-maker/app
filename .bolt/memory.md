# Project memory

## Product intent & audience

- City friendship app for verified users to find plans, connect via map, and build trust through attendance and ratings
- Mobile-first audience seeking real-world social activities and group connections
- Core flows: discover plans, join group chats, attend activities, build trust/reputation

## Brand personality & voice

- Friendly, approachable, community-oriented
- Explanatory/helpful tone (e.g., "How Conecta works" guide)
- Encourages real-world meetups and trust-building

## Visual design & UX direction

- Mobile-first Expo app
- Home tab features tappable category filter chips: All plans, Outdoors, Food & drink(s), Sports
- Selected filter dynamically updates the visible plan feed
- "How it works" presented as darkened overlay/modal (backdrop blackout) with close via X button or "Got it" button
- Overlay content: discover plans, join group chats, attend activities, build trust
- Map-based connection feature expected
- Interactions: tappable chips update feed; dismissible guide overlay

## Decisions, constraints & rationale

- Expo framework
- Home filters are interactive and update the plan feed dynamically
- "How it works" uses overlay pattern rather than separate screen for easy dismissal
- Type checking used to validate screen changes
- Categories used as primary plan filtering dimension

## Open questions & assumptions

- Map screen details and implementation not yet specified
- Verification flow for users not yet detailed
- Rating/attendance trust mechanics implementation TBD
- Data source for plans (mock vs backend) not clarified
- Exact color palette and typography not yet established