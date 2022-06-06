# terraform-demo

## Architecture Evolution

### Evolution #1 - Nginx server hosted on a Standalone EC2 instance

![day1](img/arch-day1.png)


### Evolution #2 - Two Nignx servers provisioned across different AZ, with ELB to balance the traffic

![day2](img/arch-day2.png)

### Evolution #3 - Package all the resources in a module

![day3](img/arch-day3.png)