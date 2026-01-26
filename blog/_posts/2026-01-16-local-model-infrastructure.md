---
layout: default
title: Local Model Infrastructure & Network Refresh
date: 2026-01-16
---

# Long Weekend, Big Goals
## Private AI and the Bitter Lesson are not mutually exclusive

### Working Notes to move to 5L:
- http://www.incompleteideas.net/IncIdeas/BitterLesson.html
- https://en.wikipedia.org/wiki/Bitter_lesson

#### Hypothesis: We can retain human agency through getting distilled private AI models  into the hands of humans as normal technology, insteadof feeding large frontier models. 

Currently, Large frontier models:
- take human data without compensation
- raise the prices of our electricity to generate better correlations between our data
- sold back to us via existing big-tech advertising ecosystem, or monthly subscription fees
- tripled the prices of consumer equipment (Disk, Ram) lowering 
- add environmental impact for gas turbines (until we replace them)

Not a great deal.

Local Private AI is the how we retain human agency - trained for us, by us. Blue Pill. Every post on reddit, google search, funny video provides higher-quality input data to the next pre-training or synehtic training run.

So what if we, as a society, make a choice to starve the models and instead allocate the capital to narrow-AI that runs in the house? 


## Infrastructure Catch-Up

Spent some time this week finally getting my head around farming out to multiple backends:
- Modal
- Daytona
- People
- Laptop
- (Come Monday) RocM on our new AMD Strix Halo Node

## Daytona Pipelines for Retraining

Got **[Daytona](https://daytona.io/)** vibe  configured for self-hosted model development to train the "End to End" Pipeline from Data Wrangling to Quantizing for a RPI with executorch. 

I'll begin picking through the AI generated mistakes this week, hopefully ahead of a thursday meetup.

## Modal Pipelines for Retraining

Speaking of fine-tuning, **[Modal](https://modal.com/)** is online now and the sandbox funciton is quite interesting.  Apparently all the big frontier labs are investing massively in container/vm boot times...


## ExecuTorch for Edge Deployment

On the deployment side, **[ExecuTorch](https://pytorch.org/executorch/)** has been a game changer for edge inference. I've got my first toy model running on a rpi4, after fixing a bug (pending merge). Exciting stuff.

Currently targeting:
- Home automation nodes for presence/motion detection
- Local NVR processing for doorbell and camera feeds
- Standard x86 inference for dev workloads

The export pipeline from PyTorch is surprisingly smooth. Quantized models run comfortably on constrained hardware. Local inference means no cloud dependencies for privacy-sensitive detection tasks.

Now I just need a better model (e.g. nothing I've hand rolled)

## IPv6 ULA for IoT Network

Network refresh time. Revisiting IPv6 ULA (Unique Local Addresses) for my multi-building network isolation.

```
fd79:797a:e9ef::/48 is the base prefix
```

ULA gives me RFC 4193 compliant private addressing without the NAT mess of IPv4. Each device gets a stable, routable address within its VLAN. Benefits:

- No NAT traversal headaches
- Consistent addressing across reboots
- Clean separation from public-facing network
- WireGuard tunnel endpoints are trivial to configure

### Address Allocation

```
fd79:797a:e9ef:0000::/52 → Building 1 (Guest/IoT - 512+ devices)
├── fd79:797a:e9ef:0000::/56 → Mixed Network (Phones, Desktops)
├── fd79:797a:e9ef:0100::/56 → Guest/Untrusted Network
├── fd79:797a:e9ef:0200::/56 → IoT Network
└── fd79:797a:e9ef:0300::/56 → Reserved

fd79:797a:e9ef:0400::/58 → Building 2 (60 devices)
fd79:797a:e9ef:0401::/58 → Building 3 (60 devices)
fd79:797a:e9ef:0402::/58 → Building 4 (reserved)
fd79:797a:e9ef:0403::/58 → Building 5 (reserved)
fd79:797a:e9ef:0404::/58 → Building 6 (reserved)
```

Building 1 gets a /52, giving me room to split into multiple /56 subnets as needed. Buildings 2 and 3 use /58s (64 addresses each) for up to 60 devices.

### Configuration Example (Debian Router)

```bash
# /etc/network/interfaces.d/building1-mixed
auto b1-mixed
iface b1-mixed inet6 static
address fd79:797a:e9ef:0000::1
netmask 56
gateway fd79:797a:e9ef:ffff::1

# /etc/network/interfaces.d/building1-guest
auto b1-guest
iface b1-guest inet6 static
address fd79:797a:e9ef:0100::1
netmask 56

# /etc/network/interfaces.d/building1-iot
auto b1-iot
iface b1-iot inet6 static
address fd79:797a:e9ef:0200::1
netmask 56
```

### DNS Setup (Pi-hole)

Pi-hole handles DNS for each network segment, providing consistent resolution and filtering:

```
# Pi-hole can bind to specific interfaces
PIHOLE_INTERFACE=b1-mixed
DNSMASQ_LISTENING=local
```

### Firewall Rules (nftables)

```bash
# nftables snippet for Building 1 boundary
table ip6 filter {
    chain forward {
        # Allow established/related connections
        iifname "b1-mixed" oifname "wan" ct state established,related accept
        iifname "b1-guest" oifname "wan" ct state established,related accept
        iifname "b1-iot" oifname "wan" ct state established,related accept

        # Block guest from reaching mixed network
        iifname "b1-guest" oifname "b1-mixed" drop

        # Block guest from reaching IoT network
        iifname "b1-guest" oifname "b1-iot" drop

        # Allow IoT to initiate to mixed if needed
        iifname "b1-iot" oifname "b1-mixed" accept

        # Allow all outbound from mixed
        oifname "b1-mixed" accept
        oifname "b1-guest" accept
        oifname "b1-iot" accept
    }
}
```

### Routing Architecture

```
[ISP Gateway]
       |
       v
[Debian Router]
       |
   +---+---+---+---+---+
   |    |    |    |    |
 [B1-  [B1-  [B1-  [B2]  [B3]
 Mixed] Guest] IoT]     |
                          (B4-B6 reserved)
```

Static routes on the router handle inter-VLAN communication. The /52 for Building 1 keeps all Guest/IoT networks under one administrative block while maintaining clear security boundaries between untrusted and trusted segments.

## What's Next

This infrastructure foundation unlocks a few projects I've been wanting to build:
- Local-first personal AI assistant with retrieval augmented generation
- Automated model distillation pipeline
- IoT sensor network with on-edge inference

The pieces are starting to click together.
