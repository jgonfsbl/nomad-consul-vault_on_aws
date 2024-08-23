# Permissions
![image](https://github.com/user-attachments/assets/8041e12a-d312-4193-bd8d-c279d873b68a)

# Trust relationships
<img width="1172" alt="image" src="https://github.com/user-attachments/assets/34ec4f4e-4df2-4174-913f-ac9d771ed539">

Text version of the same trust policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
