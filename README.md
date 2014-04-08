mysql_multi Cookbook
====================
Creates a multiple mysql instance under the mysqld_multi management.

Requirements
------------

#### packages
- `mysql` - mysql_multi needs mysql to create the instance.

Attributes
----------

Usage
-----
#### mysql_multi::default

```json
{
  "mysql_multi": [
    {
      "base": "mysql1",
      "service": "mysqld1",
      "port": "3306"
    },
    {
      "base": "mysql2",
      "service": "mysqld2",
      "port": "3307"
    }
  ],
}
```

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Yusuke Tanaka (Akatsuki, Inc.)

under MIT License
