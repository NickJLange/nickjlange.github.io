---
layout: default
title: Local Model Infrastructure & Network Refresh
date: 2026-01-16
---

# Infrastructure Catch-Up

Spent some time this week finally getting my local model infrastructure dialed in. Here's what's been keeping me busy.

## Daytona Setup Complete

Got **[Daytona](https://daytona.io/)** fully configured for self-hosted model development. The UX is surprisingly polished - spins up dev environments in seconds with GPU access. Now I can iterate on model experiments without eating through my local compute budget.

The killer feature for me is the pre-configured templates for common ML stacks. Jumped straight into fine-tuning without fighting environment config. Currently using it for vision model experiments - the CUDA environments just work out of the box.

## Modal Pipelines for Retraining

Speaking of fine-tuning, **[Modal](https://modal.com/)** has become the backbone for automating model retraining. Built a pipeline that:

- Ingests new training data from my home camera feeds
- Triggers fine-tuning jobs on custom object/person detection models
- Validates output quality automatically on scheduled batches
- Deploys approved models to the serving endpoint

The key insight: small detection models fine-tuned on my specific camera angles outperform generic models on my use cases. Running custom architectures that I've iterated on for presence detection and doorbell scenarios.

```python
# Modal pipeline skeleton
@app.function()
def retrain_detection_model(dataset_path: str) -> str:
    # Load annotated frames from home cameras
    # Fine-tune with custom backbone
    # Evaluate mAP on validation set
    # Return model checkpoint if passing threshold
```

The automation means I can focus on data quality and annotation rather than babysitting training runs. Self-collected data from my own cameras gives better results than any public dataset for my specific use case.

## ExecuTorch for Edge Deployment

On the deployment side, **[ExecuTorch](https://pytorch.org/executorch/)** has been a game changer for edge inference. Moving model execution from the cloud to local devices cuts latency and costs dramatically.

Currently targeting:
- Home automation nodes for presence/motion detection
- Local NVR processing for doorbell and camera feeds
- Standard x86 inference for dev workloads

The export pipeline from PyTorch is surprisingly smooth. Quantized models run comfortably on constrained hardware. Local inference means no cloud dependencies for privacy-sensitive detection tasks.

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
