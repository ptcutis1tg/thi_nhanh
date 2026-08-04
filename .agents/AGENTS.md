# Superpowers Core Agent Guidelines

You must follow the `superpowers` software development methodology in this project.

## Bootstrap Instruction
- Before answering the user's request, starting planning mode, or writing any code, you MUST always check if a superpower skill applies.
- Start by invoking the `using-superpowers` skill. You can find it at [using-superpowers/SKILL.md](file:///c:/Users/ADMINE/Desktop/CODE/.agents/skills/using-superpowers/SKILL.md).
- Follow the workflow established by the superpowers framework:
  1. **Brainstorming**: Refine requirements using the `brainstorming` skill before proposing an implementation plan.
  2. **Plan Writing**: Detail step-by-step changes using the `writing-plans` skill.
  3. **TDD (Test-Driven Development)**: Write failing tests before writing code, and use the `test-driven-development` skill.
  4. **Subagent Execution**: Use `subagent-driven-development` to dispatch tasks to clean, focused subagents.
  5. **Verification**: Verify all changes before completion.

Please follow the rules inside each `SKILL.md` exactly as written.

## User Preferences & Custom Rules
- **Auto-push:** Từ bây giờ, mỗi lần sửa app và hoàn thành một tính năng/lỗi, tác tử (agent) phải tự động chạy lệnh git commit và git push để đẩy code lên kho lưu trữ nhằm mục đích tự động cập nhật app qua GitHub Actions.
